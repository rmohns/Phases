import AppKit
import Observation

/// Owns the schedule, decides when to change the wallpaper, and applies it.
@MainActor
@Observable
final class WallpaperScheduler {
  let library = ImageLibrary()
  let location = LocationProvider()
  let launchAtLogin = LaunchAtLogin()

  var phases: [Phase] {
    didSet {
      Self.save(phases, forKey: Keys.phases)
      if needsLocation && location.coordinate == nil { location.refresh() }
      evaluate(reloadingLibrary: false)
    }
  }

  var displayMode: DisplayMode {
    didSet {
      UserDefaults.standard.set(displayMode.rawValue, forKey: Keys.displayMode)
      reapplyCurrentPhase()
    }
  }

  var transitionStyle: TransitionStyle {
    didSet { UserDefaults.standard.set(transitionStyle.rawValue, forKey: Keys.transitionStyle) }
  }

  /// Crossfade length in seconds, within `TransitionStyle.durationRange`.
  var crossfadeDuration: Double {
    didSet { UserDefaults.standard.set(crossfadeDuration, forKey: Keys.crossfadeDuration) }
  }

  /// [D-restore-on-quit] Whether Quit puts back the pre-launch wallpaper.
  var restoresWallpaperOnQuit: Bool {
    didSet { UserDefaults.standard.set(restoresWallpaperOnQuit, forKey: Keys.restoresWallpaperOnQuit) }
  }

  /// [D-quit-confirm] Whether Quit Phases asks first.
  var asksBeforeQuitting: Bool {
    didSet { UserDefaults.standard.set(asksBeforeQuitting, forKey: Keys.asksBeforeQuitting) }
  }

  var isPaused: Bool {
    didSet {
      UserDefaults.standard.set(isPaused, forKey: Keys.isPaused)
      evaluate()
    }
  }

  private(set) var appliedState: AppliedState? {
    didSet { Self.save(appliedState, forKey: Keys.appliedState) }
  }

  /// The wallpaper from before Phases changed anything; restored on quit.
  private(set) var restorePoint: RestorePoint? {
    didSet { Self.save(restorePoint, forKey: Keys.restorePoint) }
  }

  /// Every display seen so far, connected or not (spec "Display identity").
  private(set) var knownDisplays: [KnownDisplay] {
    didSet { Self.save(knownDisplays, forKey: Keys.knownDisplays) }
  }
  private(set) var connectedDisplayUUIDs: Set<String> = []

  private(set) var activePhase: Phase?
  private(set) var nextChange: NextChange?
  /// When the next phase starts, ending the active one (nil if none is scheduled).
  private(set) var activePhaseEnds: Date?
  private(set) var isDarkMode = WallpaperScheduler.systemIsDark()

  @ObservationIgnored private var timer: Timer?
  @ObservationIgnored private let crossfade = CrossfadeController()
  @ObservationIgnored private var appearanceObservation: NSKeyValueObservation?
  /// Set at logout, restart, or shutdown, so only a real Quit restores.
  @ObservationIgnored private var isPoweringOff = false
  @ObservationIgnored private var observers: [(NotificationCenter, NSObjectProtocol)] = []

  struct NextChange: Equatable {
    var date: Date
    /// Name of the phase that starts, or nil for a rotation within the current phase.
    var phaseName: String?
  }

  private enum Keys {
    static let phases = "phases"
    static let displayMode = "displayMode"
    static let isPaused = "isPaused"
    static let appliedState = "appliedState"
    static let restorePoint = "restorePoint"
    static let knownDisplays = "knownDisplays"
    static let transitionStyle = "transitionStyle"
    static let crossfadeDuration = "crossfadeDuration"
    static let restoresWallpaperOnQuit = "restoresWallpaperOnQuit"
    static let asksBeforeQuitting = "asksBeforeQuitting"
  }

  init() {
    let defaults = UserDefaults.standard
    phases = Self.load([Phase].self, forKey: Keys.phases)
      ?? [Phase(name: "All Day", trigger: .always)]
    displayMode = defaults.string(forKey: Keys.displayMode).flatMap(DisplayMode.init) ?? .sameOnAll
    isPaused = defaults.bool(forKey: Keys.isPaused)
    restoresWallpaperOnQuit = defaults.object(forKey: Keys.restoresWallpaperOnQuit) as? Bool ?? true
    asksBeforeQuitting = defaults.object(forKey: Keys.asksBeforeQuitting) as? Bool ?? true
    transitionStyle = defaults.string(forKey: Keys.transitionStyle).flatMap(TransitionStyle.init) ?? .crossfade
    let duration = defaults.object(forKey: Keys.crossfadeDuration) as? Double ?? TransitionStyle.defaultDuration
    crossfadeDuration = min(max(duration, TransitionStyle.durationRange.lowerBound), TransitionStyle.durationRange.upperBound)
    appliedState = Self.load(AppliedState.self, forKey: Keys.appliedState)
    knownDisplays = Self.load([KnownDisplay].self, forKey: Keys.knownDisplays) ?? []
    // Keep an existing restore point: one left over from a crash still holds
    // the true original, while capturing now would record Phases' own image.
    restorePoint = Self.load(RestorePoint.self, forKey: Keys.restorePoint) ?? RestorePoint.capture()

    refreshDisplays()
    location.onChange = { [weak self] in self?.evaluate() }
    if needsLocation { location.refresh() }
    observeSystemEvents()
    evaluate()
  }

  // MARK: - Derived state

  /// [D-location-on-demand] Location is requested only once a phase uses
  /// dawn or dusk, never at launch otherwise.
  var needsLocation: Bool {
    phases.contains { $0.trigger.usesLocation }
  }

  /// The image on the main display, or any display if that's unknown.
  var currentImageName: String? {
    guard let images = appliedState?.imagesByDisplay else { return nil }
    return NSScreen.main?.displayUUID.flatMap { images[$0] } ?? images.values.first
  }

  /// Known displays, connected ones first, for the phase editor's picker.
  var displaysForPicker: [KnownDisplay] {
    knownDisplays.sorted { lhs, rhs in
      let l = connectedDisplayUUIDs.contains(lhs.uuid), r = connectedDisplayUUIDs.contains(rhs.uuid)
      if l != r { return l }
      return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
  }

  func isConnected(_ display: KnownDisplay) -> Bool {
    connectedDisplayUUIDs.contains(display.uuid)
  }

  /// Records connected displays and their current names.
  private func refreshDisplays() {
    var known = knownDisplays
    var connected: Set<String> = []
    for screen in NSScreen.screens {
      guard let uuid = screen.displayUUID else { continue }
      connected.insert(uuid)
      if let index = known.firstIndex(where: { $0.uuid == uuid }) {
        known[index].name = screen.localizedName
      } else {
        known.append(KnownDisplay(uuid: uuid, name: screen.localizedName))
      }
    }
    if known != knownDisplays { knownDisplays = known }
    connectedDisplayUUIDs = connected
  }

  // MARK: - Actions

  /// Advances to the next image in the active phase.
  func changeNow() {
    let now = Date()
    guard let active = engine.activePhase(at: now) else { return }
    let start = resolvedStart(for: active, now: now)
    let slot = slot(for: active.phase, start: start, now: now)
    let steps = appliedState?.phaseID == active.phase.id ? (appliedState?.manualSteps ?? 0) + 1 : 1
    apply(active.phase, start: start, slot: slot, manualSteps: steps)
    scheduleNextChange(from: now)
  }

  func updatePhase(_ phase: Phase) {
    guard let index = phases.firstIndex(where: { $0.id == phase.id }) else { return }
    phases[index] = phase
  }

  func addPhase() -> Phase {
    let phase = Phase(name: "New Phase", trigger: .clockTime(minutes: 9 * 60))
    phases.append(phase)
    return phase
  }

  func deletePhase(id: Phase.ID) {
    phases.removeAll { $0.id == id }
  }

  /// Phases in the order they occur through the day, "Always" first.
  var phasesByTime: [Phase] {
    let reference = Calendar.current.startOfDay(for: Date())
    return phases.sorted { lhs, rhs in
      let l = engine.occurrence(of: lhs.trigger, dayOffset: 0, from: reference) ?? .distantPast
      let r = engine.occurrence(of: rhs.trigger, dayOffset: 0, from: reference) ?? .distantPast
      return l < r
    }
  }

  // MARK: - Scheduling

  private var engine: ScheduleEngine {
    ScheduleEngine(phases: phases, location: location.coordinate, isDarkMode: isDarkMode)
  }

  /// Brings the wallpaper up to date. Safe to call any time: it only changes
  /// the wallpaper if a phase change or rotation is due (or was missed).
  func evaluate(reloadingLibrary: Bool = true) {
    let now = Date()
    if reloadingLibrary { library.reload() }
    launchAtLogin.refresh()

    guard let active = engine.activePhase(at: now) else {
      activePhase = nil
      scheduleNextChange(from: now)
      return
    }
    activePhase = active.phase
    guard !isPaused else {
      scheduleNextChange(from: now)
      return
    }

    let start = resolvedStart(for: active, now: now)
    let slot = slot(for: active.phase, start: start, now: now)

    if let state = appliedState, isSameOccurrence(state, phase: active.phase, start: start) {
      if state.rotationSlot != slot || !imagesMatchSelections(state, phase: active.phase) {
        // [D-missed-latest-only] Jumps straight to the most recent missed
        // rotation.
        apply(active.phase, start: start, slot: slot, manualSteps: state.manualSteps)
      } else if state.phaseStart != start {
        appliedState?.phaseStart = start
      }
    } else {
      apply(active.phase, start: start, slot: slot, manualSteps: 0)
    }
    scheduleNextChange(from: now)
  }

  private func reapplyCurrentPhase() {
    let now = Date()
    guard !isPaused, let active = engine.activePhase(at: now) else { return }
    let start = resolvedStart(for: active, now: now)
    apply(
      active.phase,
      start: start,
      slot: slot(for: active.phase, start: start, now: now),
      manualSteps: appliedState?.manualSteps ?? 0
    )
  }

  /// "Always" phases have no natural start, so rotation is anchored to when
  /// the phase was first applied.
  private func resolvedStart(for active: ScheduleEngine.ActivePhase, now: Date) -> Date {
    if let start = active.start { return start }
    if let state = appliedState, state.phaseID == active.phase.id { return state.phaseStart }
    return now
  }

  private func slot(for phase: Phase, start: Date, now: Date) -> Int {
    phase.rotationSeconds.map { ScheduleEngine.rotationSlot(start: start, interval: $0, now: now) } ?? 0
  }

  /// Whether every connected display shows an image from its current pool,
  /// and displays with no image have nothing to show. Catches edited
  /// selections, deleted files, and newly connected displays.
  private func imagesMatchSelections(_ state: AppliedState, phase: Phase) -> Bool {
    for uuid in connectedDisplayUUIDs {
      let pool = imagePool(for: uuid, in: phase)
      if let shown = state.imagesByDisplay[uuid] {
        if !pool.contains(shown) { return false }
      } else if !pool.isEmpty {
        return false
      }
    }
    return true
  }

  /// The available images a display draws from: its own selection if it has
  /// one (even if empty), otherwise the All Displays selection.
  private func imagePool(for uuid: String, in phase: Phase) -> [String] {
    library.availableImages(phase.displayImageNames[uuid] ?? phase.imageNames)
  }

  /// A phase occurs at most once a day, so a small shift in its start time
  /// (a location update nudging dusk) is still the same occurrence.
  private func isSameOccurrence(_ state: AppliedState, phase: Phase, start: Date) -> Bool {
    state.phaseID == phase.id && abs(state.phaseStart.timeIntervalSince(start)) < 6 * 3600
  }

  private func scheduleNextChange(from now: Date) {
    timer?.invalidate()
    timer = nil

    let nextPhase = engine.nextPhaseStart(after: now)
    activePhaseEnds = nextPhase?.date
    var next = nextPhase.map { NextChange(date: $0.date, phaseName: $0.phase.name) }
    if let active = activePhase, let interval = active.rotationSeconds, let state = appliedState,
      state.phaseID == active.id
    {
      let rotation = ScheduleEngine.nextRotation(start: state.phaseStart, interval: interval, now: now)
      if next.map({ rotation < $0.date }) ?? true {
        next = NextChange(date: rotation, phaseName: nil)
      }
    }
    nextChange = isPaused ? nil : next

    guard let next = nextChange else { return }
    // [D-single-timer] One timer aimed at the next event, re-checking at
    // least hourly as a safety net against clock drift. No polling.
    let fireDate = min(next.date.addingTimeInterval(0.5), now.addingTimeInterval(3600))
    let timer = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
      MainActor.assumeIsolated { self?.evaluate() }
    }
    timer.tolerance = 1
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  // MARK: - Applying

  /// Picks and applies an image for each connected display. Displays with
  /// nothing available keep their current wallpaper; the state is still
  /// recorded so the scheduler doesn't retry every evaluation.
  private func apply(_ phase: Phase, start: Date, slot: Int, manualSteps: Int) {
    refreshDisplays()
    let picks = pickImages(for: phase, step: slot + manualSteps)
    let assignments = NSScreen.screens.compactMap { screen -> WallpaperAssignment? in
      guard let uuid = screen.displayUUID, let name = picks[uuid], let url = library.url(for: name) else { return nil }
      return WallpaperAssignment(screen: screen, url: url)
    }
    if !assignments.isEmpty {
      crossfade.apply(assignments, duration: transitionStyle == .crossfade ? crossfadeDuration : nil)
    }
    appliedState = AppliedState(
      phaseID: phase.id, phaseStart: start, rotationSlot: slot, manualSteps: manualSteps, imagesByDisplay: picks
    )
  }

  /// Display UUID → image. Displays with their own selection draw from it;
  /// the rest share the All Displays selection per the display mode (spec "Displays sharing the All Displays images").
  private func pickImages(for phase: Phase, step: Int) -> [String: String] {
    let previous = appliedState?.imagesByDisplay ?? [:]
    let connected = NSScreen.screens.compactMap(\.displayUUID)
    var picks: [String: String] = [:]
    var sharing: [String] = []

    for uuid in connected {
      // [D-own-images-no-fallback] A display with its own selection never
      // falls back to All Displays, even if none of its images are available.
      guard phase.displayImageNames[uuid] != nil else {
        sharing.append(uuid)
        continue
      }
      let pool = imagePool(for: uuid, in: phase)
      if let name = pick(from: pool, count: 1, order: phase.order, step: step, avoiding: [previous[uuid]].compactMap { $0 }).first {
        picks[uuid] = name
      }
    }

    let shared = library.availableImages(phase.imageNames)
    if !sharing.isEmpty, !shared.isEmpty {
      let current = sharing.compactMap { previous[$0] }
      switch displayMode {
      case .sameOnAll:
        if let name = pick(from: shared, count: 1, order: phase.order, step: step, avoiding: current).first {
          for uuid in sharing { picks[uuid] = name }
        }
      case .differentPerDisplay:
        let names = pick(from: shared, count: sharing.count, order: phase.order, step: step, avoiding: current)
        for (uuid, name) in zip(sharing, names) { picks[uuid] = name }
      }
    }
    return picks
  }

  /// In order: consecutive images starting at `step`. Random: distinct where
  /// possible, preferring ones not currently showing.
  private func pick(from pool: [String], count: Int, order: ImageOrder, step: Int, avoiding current: [String]) -> [String] {
    guard !pool.isEmpty, count > 0 else { return [] }
    switch order {
    case .inOrder:
      return (0..<count).map { pool[(step + $0) % pool.count] }
    case .random:
      return randomPick(from: pool, count: count, avoiding: current)
    }
  }

  /// Distinct images where possible, preferring ones not currently showing.
  private func randomPick(from available: [String], count: Int, avoiding current: [String]) -> [String] {
    let fresh = available.filter { !current.contains($0) }.shuffled()
    let pool = fresh.count >= count ? fresh : fresh + available.filter(current.contains).shuffled()
    return (0..<count).map { pool[$0 % pool.count] }
  }

  // MARK: - System events

  private func observeSystemEvents() {
    let workspace = NSWorkspace.shared.notificationCenter
    let distributed = DistributedNotificationCenter.default()
    let local = NotificationCenter.default

    // Re-evaluate when Light/Dark Mode changes, including Auto switching.
    appearanceObservation = NSApplication.shared.observe(\.effectiveAppearance) { [weak self] _, _ in
      Task { @MainActor in
        guard let self else { return }
        let isDark = Self.systemIsDark()
        guard isDark != self.isDarkMode else { return }
        self.isDarkMode = isDark
        self.evaluate()
      }
    }

    // Give displays a moment to come back before changing the wallpaper.
    let afterWake: @Sendable (Notification) -> Void = { [weak self] _ in
      Task { @MainActor in
        try? await Task.sleep(for: .seconds(3))
        if self?.needsLocation == true { self?.location.refresh() }
        self?.evaluate()
      }
    }
    let now: @Sendable (Notification) -> Void = { [weak self] _ in
      Task { @MainActor in self?.evaluate() }
    }
    // [D-screen-change-no-reroll] [Q-screen-params-notification] This also
    // fires for Dock and menu bar changes, so only fix displays whose image no longer fits.
    let screens: @Sendable (Notification) -> Void = { [weak self] _ in
      Task { @MainActor in
        self?.refreshDisplays()
        self?.evaluate(reloadingLibrary: false)
      }
    }

    observers = [
      (workspace, workspace.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main, using: afterWake)),
      (workspace, workspace.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main, using: afterWake)),
      (workspace, workspace.addObserver(forName: NSWorkspace.willPowerOffNotification, object: nil, queue: .main) { [weak self] _ in
        MainActor.assumeIsolated { self?.isPoweringOff = true }
      }),
      (workspace, workspace.addObserver(forName: NSWorkspace.sessionDidBecomeActiveNotification, object: nil, queue: .main, using: now)),
      (distributed, distributed.addObserver(forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: .main, using: now)),
      (local, local.addObserver(forName: .NSSystemClockDidChange, object: nil, queue: .main, using: now)),
      (local, local.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: .main, using: now)),
      (local, local.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main, using: screens)),
      (local, local.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
        MainActor.assumeIsolated { self?.restoreOriginalWallpaper() }
      }),
    ]
  }

  /// [D-restore-on-quit] Puts back the pre-launch wallpaper on an actual Quit,
  /// if the preference is on; otherwise the current image stays and becomes
  /// the next launch's original. At logout or shutdown the restore point is
  /// kept, so the next launch still knows the true original.
  private func restoreOriginalWallpaper() {
    timer?.invalidate()
    crossfade.finishRunningFade()
    guard !isPoweringOff else { return }
    if restoresWallpaperOnQuit { restorePoint?.restore() }
    restorePoint = nil
  }

  private static func systemIsDark() -> Bool {
    NSApplication.shared.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
  }

  // MARK: - Persistence

  private static func save<T: Encodable>(_ value: T?, forKey key: String) {
    if let value, let data = try? JSONEncoder().encode(value) {
      UserDefaults.standard.set(data, forKey: key)
    } else {
      UserDefaults.standard.removeObject(forKey: key)
    }
  }

  private static func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
    UserDefaults.standard.data(forKey: key).flatMap { try? JSONDecoder().decode(type, from: $0) }
  }
}
