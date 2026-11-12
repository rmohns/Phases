import AppKit
import Observation

private let diagLog = Diagnostics.logger("photos")

/// Owns the schedule, decides when to change the wallpaper, and applies it.
@MainActor
@Observable
final class WallpaperScheduler {
  let library = ImageLibrary()
  let location = LocationProvider()
  let launchAtLogin = LaunchAtLogin()
  /// [D-first-launch-shows-window] True when this launch opens the window.
  let isFirstLaunch: Bool

  var phases: [Phase] {
    didSet {
      Self.save(phases, forKey: Keys.phases)
      if needsLocation && location.coordinate == nil { location.refresh() }
      evaluate(reloadingLibrary: false)
    }
  }

  var displayMode: DisplayMode {
    didSet {
      SettingsStore.defaults.set(displayMode.rawValue, forKey: Keys.displayMode)
      reapplyCurrentPhase()
    }
  }

  var transitionStyle: TransitionStyle {
    didSet {
      SettingsStore.defaults.set(transitionStyle.rawValue, forKey: Keys.transitionStyle)
      // [D-cover-only-for-crossfade] No crossfades, no covers.
      if transitionStyle != .crossfade { crossfade.removeAllCovers(reason: "Transition set to None") }
    }
  }

  /// Crossfade length in seconds, within `TransitionStyle.durationRange`.
  var crossfadeDuration: Double {
    didSet { SettingsStore.defaults.set(crossfadeDuration, forKey: Keys.crossfadeDuration) }
  }

  /// [D-restore-on-quit] Whether Quit puts back the pre-launch wallpaper.
  var restoresWallpaperOnQuit: Bool {
    didSet { SettingsStore.defaults.set(restoresWallpaperOnQuit, forKey: Keys.restoresWallpaperOnQuit) }
  }

  /// [D-quit-confirm] Whether Quit Phases asks first.
  var asksBeforeQuitting: Bool {
    didSet { SettingsStore.defaults.set(asksBeforeQuitting, forKey: Keys.asksBeforeQuitting) }
  }

  /// Pause Schedule, and the inverse of Settings' "Change wallpaper on
  /// schedule" [D-settings-schedule-switch]: one state, two controls.
  var isPaused: Bool {
    didSet {
      SettingsStore.defaults.set(isPaused, forKey: Keys.isPaused)
      if !isPaused, pausedForOutsideChangeAt != nil {
        // [D-outside-change-pauses] Resuming puts the phase's image back
        // over the pick at once: forgetting what's applied makes the
        // check below apply again.
        pausedForOutsideChangeAt = nil
        appliedState?.imagesByDisplay = [:]
        notifier.withdraw()
      }
      evaluate()
    }
  }

  /// [D-outside-change-pauses] When Phases paused itself because a
  /// wallpaper was picked elsewhere; nil for a pause from the menu.
  private(set) var pausedForOutsideChangeAt: Date? {
    didSet { Self.save(pausedForOutsideChangeAt, forKey: Keys.pausedForOutsideChangeAt) }
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
  /// [D-photos-fetch-ahead] Picks made ahead of the next scheduled change.
  @ObservationIgnored private var fetchedAhead: FetchedAhead?
  /// The change last fetched ahead for, so it's fetched for once.
  @ObservationIgnored private var fetchedAheadFor: Date?
  /// Counts changes, so a change still waiting on photos stands down when a
  /// newer one starts.
  @ObservationIgnored private var changeGeneration = 0
  @ObservationIgnored private let crossfade = CrossfadeController()
  @ObservationIgnored private let notifier = PauseNotifier()
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
    static let pausedForOutsideChangeAt = "pausedForOutsideChangeAt"
  }

  init() {
    let defaults = SettingsStore.defaults
    // [D-first-launch-shows-window] Checked before anything below is saved.
    // Any of these keys means an earlier version has run.
    isFirstLaunch = FirstLaunch.isFirstLaunch(
      hasRecordedLaunch: defaults.bool(forKey: FirstLaunch.recordKey),
      hasSavedSettings: [Keys.phases, Keys.appliedState, Keys.restorePoint, Keys.knownDisplays, Keys.isPaused]
        .contains { defaults.object(forKey: $0) != nil },
      isUITestMode: UITestMode.isOn,
      testForcesFirstLaunch: UITestMode.forcesFirstLaunch
    )
    defaults.set(true, forKey: FirstLaunch.recordKey)
    // [D-ui-test-mode] Test mode's store starts empty, so it gets the fixtures.
    phases = Self.load([Phase].self, forKey: Keys.phases)
      ?? (UITestMode.isOn ? UITestMode.fixturePhases : Phase.starterPhases)
    displayMode = defaults.string(forKey: Keys.displayMode).flatMap(DisplayMode.init) ?? .sameOnAll
    isPaused = defaults.bool(forKey: Keys.isPaused)
    pausedForOutsideChangeAt = Self.load(Date.self, forKey: Keys.pausedForOutsideChangeAt)
    restoresWallpaperOnQuit = defaults.object(forKey: Keys.restoresWallpaperOnQuit) as? Bool ?? true
    asksBeforeQuitting = defaults.object(forKey: Keys.asksBeforeQuitting) as? Bool ?? true
    transitionStyle = defaults.string(forKey: Keys.transitionStyle).flatMap(TransitionStyle.init) ?? .crossfade
    let duration = defaults.object(forKey: Keys.crossfadeDuration) as? Double ?? TransitionStyle.defaultDuration
    crossfadeDuration = min(max(duration, TransitionStyle.durationRange.lowerBound), TransitionStyle.durationRange.upperBound)
    appliedState = Self.load(AppliedState.self, forKey: Keys.appliedState)
    knownDisplays = Self.load([KnownDisplay].self, forKey: Keys.knownDisplays) ?? []
    // Keep an existing restore point: one left over from a crash still holds
    // the true original, while capturing now would record Phases' own image.
    // [D-ui-test-mode] Nothing to restore in test mode, which never changes
    // the wallpaper.
    restorePoint = UITestMode.isOn ? nil : Self.load(RestorePoint.self, forKey: Keys.restorePoint) ?? RestorePoint.capture()

    refreshDisplays()
    // [D-photos-changes] The library has already reloaded.
    library.onPhotosChange = { [weak self] in self?.evaluate(reloadingLibrary: false) }
    location.onChange = { [weak self] in self?.evaluate() }
    if needsLocation { location.refresh() }
    observeSystemEvents()
    watchForOutsideChanges()
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
    // [D-new-phase-now] Starts now, so it usually becomes active at once.
    let phase = Phase(name: "New Phase", trigger: .clockTime(roundingDown: Date()))
    phases.append(phase)
    return phase
  }

  /// [D-duplicate-phase] Saved after the original, so the original wins
  /// the start-time tie and stays active.
  func duplicatePhase(id: Phase.ID) -> Phase? {
    guard let original = phases.first(where: { $0.id == id }) else { return nil }
    let copy = original.duplicate()
    phases.append(copy)
    return copy
  }

  /// [D-phase-turn-off] Turning off the active phase switches at once,
  /// since every change to `phases` re-checks the schedule.
  func togglePhase(id: Phase.ID) {
    guard let index = phases.firstIndex(where: { $0.id == id }) else { return }
    phases[index].isOn.toggle()
  }

  func deletePhase(id: Phase.ID) {
    phases.removeAll { $0.id == id }
  }

  /// Phases in the order they occur through the day, "Always" first.
  var phasesByTime: [Phase] {
    let reference = Calendar.current.startOfDay(for: Date())
    // Sorts by the saved location even while access is denied, so a phase
    // that can't run [D-phase-cant-run] keeps its place in the list.
    let sorter = ScheduleEngine(phases: phases, location: location.coordinate, isDarkMode: isDarkMode)
    return phases.sorted { lhs, rhs in
      let l = sorter.occurrence(of: lhs.trigger, dayOffset: 0, from: reference) ?? .distantPast
      let r = sorter.occurrence(of: rhs.trigger, dayOffset: 0, from: reference) ?? .distantPast
      return l < r
    }
  }

  // MARK: - Scheduling

  /// [D-phase-cant-run] Skips every disabled phase, whatever the reason.
  /// [D-denied-means-off] Uses only a location the schedule may use.
  private var engine: ScheduleEngine {
    ScheduleEngine(
      phases: PhaseAvailability.runnablePhases(
        phases, savedLocation: location.coordinate, isLocationDenied: location.isDenied
      ),
      location: location.usableCoordinate,
      isDarkMode: isDarkMode
    )
  }

  /// Brings the wallpaper up to date. Safe to call any time: it only changes
  /// the wallpaper if a phase change or rotation is due (or was missed).
  func evaluate(reloadingLibrary: Bool = true) {
    let now = Date()
    if reloadingLibrary { library.reload() }
    launchAtLogin.refresh()
    // [D-photos-fetch-ahead] Anything that affects the picks made ahead
    // (the phase, its images, the displays) changed: pick and fetch again
    // now, not at the change.
    if let ahead = fetchedAhead {
      let phase = phases.first { $0.id == ahead.target.phaseID }
      if phase.map(pickInputs(for:)) != ahead.inputs { forgetFetchedAhead() }
    }

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

    let pools = Dictionary(uniqueKeysWithValues: connectedDisplayUUIDs.map { ($0, imagePool(for: $0, in: active.phase)) })
    switch WallpaperCheck.action(applied: appliedState, phaseID: active.phase.id, start: start, slot: slot, pools: pools) {
    case .apply(let manualSteps):
      apply(active.phase, start: start, slot: slot, manualSteps: manualSteps)
    case .updateStart:
      appliedState?.phaseStart = start
    case .nothing:
      break
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

  /// The available images a display draws from: its own selection if it has
  /// one (even if empty), otherwise the All Displays selection.
  private func imagePool(for uuid: String, in phase: Phase) -> [String] {
    library.availableImages(phase.displayImageNames[uuid] ?? phase.imageNames)
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
    // [D-photos-fetch-ahead] Photos for the next change are fetched ahead
    // of it, once per change.
    let changeDate = next.date.addingTimeInterval(0.5)
    let fetchDate = library.sources.contains(where: \.isPhotos) && fetchedAheadFor != next.date
      ? FetchAhead.fetchDate(
        // A rotation's lead depends on its interval; a phase start's doesn't.
        forChangeAt: next.date, rotationInterval: next.phaseName == nil ? activePhase?.rotationSeconds : nil, now: now
      )
      : nil
    // [D-single-timer] One timer aimed at the next event (a change, or a
    // fetch ahead of one), re-checking at least hourly as a safety net
    // against clock drift. No polling.
    let fireDate = min(fetchDate ?? changeDate, changeDate, now.addingTimeInterval(3600))
    let isFetch = fetchDate.map { $0 <= changeDate && fireDate == $0 } ?? false
    let timer = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
      MainActor.assumeIsolated {
        guard let self else { return }
        // A fetch timer that fired late, at or after its change, runs the
        // change instead, so it isn't skipped.
        if isFetch, Date() < next.date {
          self.fetchAhead(forChangeAt: next.date)
          self.scheduleNextChange(from: Date())
        } else {
          self.evaluate()
        }
      }
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
    let target = FetchedAhead.Target(phaseID: phase.id, start: start, step: slot + manualSteps)
    // [D-photos-fetch-ahead] The picks made ahead, unless anything that
    // affects them has changed since, including a photo leaving its album.
    // Only at the change they were made for: Change Now just before it
    // reaches the same step, but mustn't take them.
    var picks: [String: String]
    if let ahead = fetchedAhead, Date() >= ahead.changeDate, ahead.target == target,
      ahead.inputs == pickInputs(for: phase)
    {
      picks = ahead.picks
      fetchedAhead = nil
    } else {
      picks = pickImages(for: phase, step: slot + manualSteps)
      // Anything applied in between may change what the next change
      // shows, so fetch for it again.
      forgetFetchedAhead()
    }
    appliedState = AppliedState(
      phaseID: phase.id, phaseStart: start, rotationSlot: slot, manualSteps: manualSteps, imagesByDisplay: picks
    )
    changeGeneration += 1
    let generation = changeGeneration

    // Photos not on hand: fetch them (a failed fetch ahead is tried again
    // here), and wait up to 30 s before showing what there is.
    let missing = Set(picks.values).filter { library.isPhoto($0) && library.cachedFile(for: $0) == nil }
    guard !missing.isEmpty else {
      show(picks)
      return
    }
    let fetches = missing.compactMap { library.fetchPhoto($0) }
    Task { @MainActor [weak self] in
      await Self.wait(for: fetches, atMost: FetchAhead.waitLimit)
      // Stand down if a newer change started, or if Phases paused (Pause,
      // or a wallpaper picked outside Phases [D-outside-change-pauses]) or
      // the phase stopped running while it waited.
      guard let self, generation == self.changeGeneration, !self.isPaused,
        self.appliedState?.phaseID == phase.id,
        self.engine.activePhase(at: Date())?.phase.id == phase.id
      else { return }
      self.showFallingBack(picks, phase: phase)
    }
  }

  /// [D-photos-fetch-ahead] Picks made ahead are no good: fetch again for
  /// the next change, from now if its lead has begun.
  private func forgetFetchedAhead() {
    fetchedAhead = nil
    fetchedAheadFor = nil
  }

  /// [D-photos-fetch-ahead] Shows the picks, giving a display whose photo
  /// couldn't be had another image from its selection that's on hand, or
  /// leaving it as it is.
  private func showFallingBack(_ picks: [String: String], phase: Phase) {
    let showing = imagesShowing()
    var shown: [String: String?] = picks
    // Displays sharing All Displays in Same on All get one replacement.
    var sharedReplacement: [String: String?] = [:]
    for (uuid, name) in picks.sorted(by: { $0.key < $1.key }) where library.fileOnHand(for: name) == nil {
      let hasOwn = phase.displayImageNames[uuid] != nil
      if !hasOwn, displayMode == .sameOnAll, let replacement = sharedReplacement[name] {
        shown[uuid] = replacement
        continue
      }
      let pool = hasOwn ? imagePool(for: uuid, in: phase) : library.availableImages(phase.imageNames)
      let onHand = Set(pool.filter { library.fileOnHand(for: $0) != nil })
      let replacement = FetchAhead.replacement(
        for: name, in: pool, onHand: onHand, order: phase.order, showing: showing[uuid] ?? []
      )
      shown[uuid] = replacement
      if !hasOwn { sharedReplacement[name] = replacement }
      diagLog.log("photo not on hand for \(uuid, privacy: .public); \(replacement == nil ? "keeping the wallpaper" : "showing another image", privacy: .public)")
    }
    // In order carries on from the planned position; only what shows
    // differs. A display keeping its wallpaper keeps the planned pick in
    // its record, so later checks don't apply again before the next change
    // [D-screen-change-no-reroll]; the photo shows from then on only if a
    // later change picks it.
    if var state = appliedState {
      for (uuid, name) in shown {
        if let name { state.imagesByDisplay[uuid] = name }
      }
      appliedState = state
    }
    show(shown.compactMapValues { $0 })
  }

  /// Sets each display's image, through the crossfade.
  private func show(_ picks: [String: String]) {
    let assignments = NSScreen.screens.compactMap { screen -> WallpaperAssignment? in
      guard let uuid = screen.displayUUID, let name = picks[uuid], let url = library.fileOnHand(for: name) else {
        return nil
      }
      return WallpaperAssignment(screen: screen, url: url)
    }
    // [D-ui-test-mode] Test mode records what it would show but never shows it.
    guard !assignments.isEmpty, !UITestMode.isOn else { return }
    // [D-scoped-bookmarks] Open while the images are read. A cover
    // remade later (a Space switch) reads without it; the sandbox change
    // has to revisit that.
    library.withAccessToAllSources {
      crossfade.apply(assignments, duration: transitionStyle == .crossfade ? crossfadeDuration : nil)
    }
    for assignment in assignments { library.photoCache.noteShown(assignment.url) }
    cleanUpPhotoCache()
  }

  /// [D-photos-cache] Never deletes what's showing, what the wallpaper
  /// store names (other Spaces), the restore record's files, or what's
  /// fetched ahead.
  private func cleanUpPhotoCache() {
    guard library.sources.contains(where: \.isPhotos) || !library.photoCacheIsEmpty else { return }
    var protected = Set(NSScreen.screens.compactMap { NSWorkspace.shared.desktopImageURL(for: $0)?.lastPathComponent })
    // Covers: the incoming file of a fade, and a change pending on a Space
    // that isn't showing [D-change-stays-on-its-space].
    protected.formUnion(crossfade.coverFileNames)
    protected.formUnion(restorePoint?.displays.compactMap { $0.imageURL?.lastPathComponent } ?? [])
    protected.formUnion(fetchedAhead?.picks.values.compactMap { library.cachedFile(for: $0)?.lastPathComponent } ?? [])
    library.photoCache.cleanUp(protected: protected, storeFileNames: WallpaperStoreWatcher.shared.fileNamesInStore())
  }

  /// Returns when every fetch has finished or `limit` has passed, whichever
  /// is first. The fetches carry on either way.
  private static func wait(for fetches: [Task<URL?, Never>], atMost limit: TimeInterval) async {
    final class Once { var done = false }
    let once = Once()
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      Task { @MainActor in
        for fetch in fetches { _ = await fetch.value }
        guard !once.done else { return }
        once.done = true
        continuation.resume()
      }
      Task { @MainActor in
        try? await Task.sleep(for: .seconds(limit))
        guard !once.done else { return }
        once.done = true
        continuation.resume()
      }
    }
  }

  // MARK: - Fetching ahead

  /// [D-photos-fetch-ahead] Picks made ahead of a scheduled change, and
  /// what they were picked from, so a change in any of it means picking
  /// again.
  struct FetchedAhead {
    struct Target: Equatable {
      var phaseID: UUID
      var start: Date
      var step: Int
    }

    struct Inputs: Equatable {
      var phase: Phase
      var displays: Set<String>
      var displayMode: DisplayMode
      var pools: [String: [String]]
    }

    var changeDate: Date
    var target: Target
    var inputs: Inputs
    var picks: [String: String]
  }

  private func pickInputs(for phase: Phase) -> FetchedAhead.Inputs {
    FetchedAhead.Inputs(
      phase: phase,
      displays: connectedDisplayUUIDs,
      displayMode: displayMode,
      pools: Dictionary(uniqueKeysWithValues: connectedDisplayUUIDs.map { ($0, imagePool(for: $0, in: phase)) })
    )
  }

  /// Picks the images the change at `date` will show, as `evaluate` would
  /// then, and starts fetching its photos.
  private func fetchAhead(forChangeAt date: Date) {
    fetchedAheadFor = date
    let at = date.addingTimeInterval(0.5)
    guard !isPaused, let active = engine.activePhase(at: at) else { return }
    refreshDisplays()
    let start = active.start ?? (appliedState?.phaseID == active.phase.id ? appliedState?.phaseStart : nil) ?? at
    let slot = slot(for: active.phase, start: start, now: at)
    let pools = Dictionary(uniqueKeysWithValues: connectedDisplayUUIDs.map { ($0, imagePool(for: $0, in: active.phase)) })
    guard case .apply(let manualSteps) = WallpaperCheck.action(
      applied: appliedState, phaseID: active.phase.id, start: start, slot: slot, pools: pools
    ) else { return }
    let picks = pickImages(for: active.phase, step: slot + manualSteps)
    fetchedAhead = FetchedAhead(
      changeDate: date,
      target: .init(phaseID: active.phase.id, start: start, step: slot + manualSteps),
      inputs: pickInputs(for: active.phase),
      picks: picks
    )
    let photos = Set(picks.values).filter(library.isPhoto)
    for name in photos { _ = library.fetchPhoto(name) }
    diagLog.log("fetching ahead: \(photos.count) photos for \(date, privacy: .public)")
  }

  /// Display UUID → image. Displays with their own selection draw from it;
  /// the rest share the All Displays selection per the display mode (spec "Displays sharing the All Displays images").
  private func pickImages(for phase: Phase, step: Int) -> [String: String] {
    let showing = imagesShowing()
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
      if let name = pick(from: pool, count: 1, order: phase.order, step: step, showing: [showing[uuid] ?? []]).first {
        picks[uuid] = name
      }
    }

    let shared = library.availableImages(phase.imageNames)
    if !sharing.isEmpty, !shared.isEmpty {
      let current = sharing.map { showing[$0] ?? [] }
      switch displayMode {
      case .sameOnAll:
        let name = phase.order == .random
          ? RandomPicker.shared(from: shared, showing: current)
          : pick(from: shared, count: 1, order: phase.order, step: step, showing: current).first
        if let name {
          for uuid in sharing { picks[uuid] = name }
        }
      case .differentPerDisplay:
        let names = pick(from: shared, count: sharing.count, order: phase.order, step: step, showing: current)
        for (uuid, name) in zip(sharing, names) { picks[uuid] = name }
      }
    }
    return picks
  }

  /// Display UUID → the images it may be showing: what Phases last set there,
  /// and what macOS reports for the current Space, which differs after a
  /// Space switch [D-cover-per-space] or a wallpaper set outside Phases.
  private func imagesShowing() -> [String: Set<String>] {
    var showing: [String: Set<String>] = [:]
    for (uuid, name) in appliedState?.imagesByDisplay ?? [:] { showing[uuid, default: []].insert(name) }
    for screen in NSScreen.screens {
      guard let uuid = screen.displayUUID,
        let url = NSWorkspace.shared.desktopImageURL(for: screen),
        let name = library.name(for: url)
      else { continue }
      showing[uuid, default: []].insert(name)
    }
    return showing
  }

  /// In order: consecutive images starting at `step`. Random: each display
  /// gets an image it isn't showing where possible (issue #10).
  private func pick(from pool: [String], count: Int, order: ImageOrder, step: Int, showing: [Set<String>]) -> [String] {
    guard !pool.isEmpty, count > 0 else { return [] }
    switch order {
    case .inOrder:
      return (0..<count).map { pool[(step + $0) % pool.count] }
    case .random:
      return RandomPicker.perDisplay(from: pool, showing: showing)
    }
  }

  // MARK: - Wallpaper changed outside Phases

  private func watchForOutsideChanges() {
    // [D-ui-test-mode] Test mode never changes the wallpaper, so it has
    // nothing to step aside from.
    guard !UITestMode.isOn else { return }
    notifier.onResume = { [weak self] in self?.isPaused = false }
    WallpaperStoreWatcher.shared.onOutsideChange = { [weak self] changes in self?.wallpaperChangedOutside(changes) }
    WallpaperStoreWatcher.shared.start()
  }

  /// [D-outside-change-pauses] Steps aside: reveals the pick, makes it the
  /// original that Quit restores, and pauses everything.
  private func wallpaperChangedOutside(_ changes: [OutsideChange]) {
    let screens = NSScreen.screens.filter { screen in
      changes.contains { $0.displayUUID == nil || $0.displayUUID == screen.displayUUID }
    }
    let displayIDs = Set(screens.compactMap(\.displayID))
    crossfade.revealWallpaper(on: displayIDs, duration: transitionStyle == .crossfade ? crossfadeDuration : nil)
    if let restorePoint {
      self.restorePoint = restorePoint.replacing(displayIDs, from: RestorePoint.capture())
    }
    let wasPaused = isPaused
    pausedForOutsideChangeAt = Date()
    if !wasPaused {
      isPaused = true
      notifier.notifyPaused()
    }
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
        // [D-cover-follows-displays]
        self?.crossfade.screensChanged()
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
    // [D-cover-pause-quit] At logout or shutdown the covers go with the process.
    guard !isPoweringOff else { return }
    if restoresWallpaperOnQuit { restorePoint?.restore() }
    restorePoint = nil
    // [D-cover-pause-quit] After the restore, so the real wallpaper is in place.
    crossfade.removeAllCovers(reason: "Quit")
  }

  private static func systemIsDark() -> Bool {
    NSApplication.shared.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
  }

  // MARK: - Persistence

  private static func save<T: Encodable>(_ value: T?, forKey key: String) {
    if let value, let data = try? JSONEncoder().encode(value) {
      SettingsStore.defaults.set(data, forKey: key)
    } else {
      SettingsStore.defaults.removeObject(forKey: key)
    }
  }

  private static func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
    SettingsStore.defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(type, from: $0) }
  }
}
