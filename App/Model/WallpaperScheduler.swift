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

  private(set) var activePhase: Phase?
  private(set) var nextChange: NextChange?
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
    static let transitionStyle = "transitionStyle"
    static let crossfadeDuration = "crossfadeDuration"
  }

  init() {
    let defaults = UserDefaults.standard
    phases = Self.load([Phase].self, forKey: Keys.phases)
      ?? [Phase(name: "All Day", trigger: .always)]
    displayMode = defaults.string(forKey: Keys.displayMode).flatMap(DisplayMode.init) ?? .sameOnAll
    isPaused = defaults.bool(forKey: Keys.isPaused)
    transitionStyle = defaults.string(forKey: Keys.transitionStyle).flatMap(TransitionStyle.init) ?? .crossfade
    let duration = defaults.object(forKey: Keys.crossfadeDuration) as? Double ?? TransitionStyle.defaultDuration
    crossfadeDuration = min(max(duration, TransitionStyle.durationRange.lowerBound), TransitionStyle.durationRange.upperBound)
    appliedState = Self.load(AppliedState.self, forKey: Keys.appliedState)
    // Keep an existing restore point: one left over from a crash still holds
    // the true original, while capturing now would record Phases' own image.
    restorePoint = Self.load(RestorePoint.self, forKey: Keys.restorePoint) ?? RestorePoint.capture()

    location.onChange = { [weak self] in self?.evaluate() }
    if needsLocation { location.refresh() }
    observeSystemEvents()
    evaluate()
  }

  // MARK: - Derived state

  var needsLocation: Bool {
    phases.contains { $0.trigger.usesLocation }
  }

  var currentImageName: String? {
    appliedState?.imageNames.first
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
    let available = library.availableImages(for: active.phase)

    if let state = appliedState, isSameOccurrence(state, phase: active.phase, start: start) {
      let imagesStillValid = state.imageNames.allSatisfy(available.contains)
      let imagesNewlyAvailable = state.imageNames.isEmpty && !available.isEmpty
      if state.rotationSlot != slot || !imagesStillValid || imagesNewlyAvailable {
        // Jumps straight to the most recent missed rotation.
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

  /// A phase occurs at most once a day, so a small shift in its start time
  /// (a location update nudging dusk) is still the same occurrence.
  private func isSameOccurrence(_ state: AppliedState, phase: Phase, start: Date) -> Bool {
    state.phaseID == phase.id && abs(state.phaseStart.timeIntervalSince(start)) < 6 * 3600
  }

  private func scheduleNextChange(from now: Date) {
    timer?.invalidate()
    timer = nil

    var next = engine.nextPhaseStart(after: now).map { NextChange(date: $0.date, phaseName: $0.phase.name) }
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
    // Re-check at least hourly as a safety net against clock drift.
    let fireDate = min(next.date.addingTimeInterval(0.5), now.addingTimeInterval(3600))
    let timer = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
      MainActor.assumeIsolated { self?.evaluate() }
    }
    timer.tolerance = 1
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  // MARK: - Applying

  private func apply(_ phase: Phase, start: Date, slot: Int, manualSteps: Int) {
    let available = library.availableImages(for: phase)
    guard !available.isEmpty else {
      // Nothing to show; remember the phase so we don't retry every evaluation.
      appliedState = AppliedState(
        phaseID: phase.id, phaseStart: start, rotationSlot: slot, manualSteps: manualSteps, imageNames: []
      )
      return
    }

    let count = displayMode == .sameOnAll ? 1 : max(NSScreen.screens.count, 1)
    let names: [String]
    switch phase.order {
    case .inOrder:
      let base = slot + manualSteps
      names = (0..<count).map { available[(base + $0) % available.count] }
    case .random:
      names = randomPick(from: available, count: count, avoiding: appliedState?.imageNames ?? [])
    }

    crossfade.apply(
      names.compactMap(library.url(for:)),
      duration: transitionStyle == .crossfade ? crossfadeDuration : nil
    )
    appliedState = AppliedState(
      phaseID: phase.id, phaseStart: start, rotationSlot: slot, manualSteps: manualSteps, imageNames: names
    )
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
    let screens: @Sendable (Notification) -> Void = { [weak self] _ in
      Task { @MainActor in self?.reapplyCurrentPhase() }
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

  /// Puts back the pre-launch wallpaper on an actual Quit. At logout or
  /// shutdown the restore point is kept, so the next launch still knows the
  /// true original.
  private func restoreOriginalWallpaper() {
    timer?.invalidate()
    crossfade.finishRunningFade()
    guard !isPoweringOff else { return }
    restorePoint?.restore()
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
