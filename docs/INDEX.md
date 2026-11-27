# Phases — Tag index

Every `[D-…]`, `[Q-…]`, `[L-…]`, and `[X-…]` tag: where it's defined,
what it says, and which Swift files cite it. **Generated; don't edit by
hand.** The unit tests rewrite this file when it's out of date and fail
once, so commit the new version (`[D-doc-check]`, TESTING.md "Unit
tests"). Line numbers are as of the last run.

## Decisions `[D-…]`

| Tag | Where | Says | Cited in code |
|---|---|---|---|
| `[D-active-badge]` | spec/window.md:129 "Phases window (one window for everything)" | The active phase is marked with the word "Active" | PhasesWindow.swift, SidebarHighlight.swift, SidebarHighlightTests.swift |
| `[D-aerials-untouched]` | spec/launch-and-quit.md:53 "Restore original wallpaper on quit" | Aerials and other system wallpapers | OutsideChangeRule.swift, RestorePoint.swift, SystemWallpaperCheck.swift, SystemWallpaperCheckTests.swift, SystemWallpaperInspector.swift |
| `[D-app-menu]` | spec/interface.md:188 "Dock icon and app menu" | While the window is open, Phases has a standard menu bar | PhasesCommands.swift, PhasesWindow.swift, SettingsView.swift |
| `[D-brand-egg]` | spec/window.md:72 "Phases window (one window for everything)" | Easter egg: click the panel and it turns into a meme | PhasesWindow.swift |
| `[D-brand-fixed-text]` | spec/window.md:52 "Phases window (one window for everything)" | Fixed text sizes | PhasesWindow.swift |
| `[D-brand-inset]` | spec/window.md:21 "Phases window (one window for everything)" | Edges line up with the traffic lights and row icons | PhaseEditor.swift, PhasesWindow.swift |
| `[D-brand-layout]` | spec/window.md:47 "Phases window (one window for everything)" | *Why:* the first tagline ("Wallpaper sets for every phase of your day", 10 pt) wrapped awkwardly and was hard to read; with a 64 pt icon … | AppearanceTests.swift, PhasesWindow.swift |
| `[D-brand-legibility]` | spec/window.md:61 "Phases window (one window for everything)" | Legibility | PhasesWindow.swift |
| `[D-brand-scrolls]` | spec/window.md:69 "Phases window (one window for everything)" | It's the first item in the sidebar list, so it **scrolls away** when there are enough phases to scroll; it's never pinned | PhasesWindow.swift |
| `[D-bundle-id-settings-move]` | spec/project.md:48 "Project and bundle ID" | Settings move to the new ID once, by hand, from the shell |  |
| `[D-bundle-id]` | spec/project.md:35 "Project and bundle ID" | The bundle ID is `com.robertmohns.phases` |  |
| `[D-change-stays-on-its-space]` | spec/transitions.md:145 "The persistent cover" | A change belongs to the Space it was made on, even if you leave mid-fade | CrossfadeController.swift, WallpaperScheduler.swift |
| `[D-close-stays-here]` | spec/interface.md:113 "Dock icon and app menu" | Closing the window keeps you on the current Space | FocusHandoff.swift, HandoffChoice.swift, HandoffChoiceTests.swift, PhasesApp.swift, WindowLayoutConfigurator.swift |
| `[D-connected-displays-only]` | spec/displays.md:111 "Display identity" | Only connected displays are shown | DisplayTabs.swift, PhaseEditor.swift, PhaseEditorRulesTests.swift, WallpaperScheduler.swift |
| `[D-content-vs-tools]` | spec/interface.md:13 "Interface" | Controls stay clearly separate from content | EditorBox.swift |
| `[D-cover-checks]` | testing/cover-checks.md:11 "Cover checks (draft 33)" | The persistent cover is checked by hand before it merges, and again after any change to `CrossfadeController` |  |
| `[D-cover-follows-displays]` | spec/transitions.md:281 "The persistent cover" | Covers follow display changes | CrossfadeController.swift, WallpaperScheduler.swift |
| `[D-cover-iosurface]` | spec/transitions.md:332 "A change, step by step" | Each cover holds one copy of its image, and only while it's up | CoverSurface.swift, CoverSurfaceTests.swift, CrossfadeController.swift |
| `[D-cover-level]` | spec/transitions.md:90 "The persistent cover" | It sits just above the desktop picture and below the desktop icons, so icons and windows don't flicker | CrossfadeController.swift |
| `[D-cover-only-for-crossfade]` | spec/transitions.md:244 "The persistent cover" | No cover at all unless crossfades will actually play | CrossfadeController.swift, WallpaperScheduler.swift |
| `[D-cover-opacity]` | spec/transitions.md:262 "The persistent cover" | The cover is 99% opaque, not 100% | CrossfadeController.swift |
| `[D-cover-pause-quit]` | spec/transitions.md:392 "A change, step by step" | Pause, Quit, and crashes | CrossfadeController.swift, WallpaperScheduler.swift |
| `[D-cover-per-space]` | spec/transitions.md:116 "The persistent cover" | Each Space keeps its own wallpaper | CrossfadeController.swift, WallpaperScheduler.swift |
| `[D-debug-test-folder]` | spec/sandbox.md:81 "Entitlements" | Debug builds can also read one test folder; Release builds, the ones that ship, can't | EntitlementsTests.swift, TestImages.swift |
| `[D-delete-selects-next]` | spec/window.md:170 "Phases window (one window for everything)" | After deleting a phase, the next phase down is selected | PhaseListSelection.swift, PhaseListSelectionTests.swift, PhaseListTests.swift, PhasesWindow.swift, UITestMode.swift |
| `[D-denied-means-off]` | spec/schedule.md:180 "Location" | Denied means no location at all, saved or fresh | LocationProvider.swift, PhaseAvailability.swift, PhaseAvailabilityTests.swift, WallpaperScheduler.swift |
| `[D-diagnostics-switch]` | TEST-TOOLS.md:148 "Diagnostics" | Diagnostic logging is built in and off by default | Diagnostics.swift, FocusHandoff.swift, PhasesWindow.swift, ReopenHandler.swift, WindowLayoutConfigurator.swift, WindowRequest.swift, WindowSpaceMover.swift |
| `[D-display-tab-shapes]` | spec/displays.md:61 "Per-display images" | A display's tab draws its outline at its real proportions | DisplayTabs.swift, PhaseEditorRulesTests.swift |
| `[D-display-tabs-visibility]` | spec/displays.md:73 "Per-display images" | The tab row shows when more than one display is connected | DisplayTabs.swift, PhaseEditorRulesTests.swift |
| `[D-display-tabs]` | spec/displays.md:21 "Per-display images" | The phase editor picks a display with a row of display tabs | DisplayTabs.swift, DisplayTabsRow.swift, PhaseEditor.swift, PhaseEditorRulesTests.swift, WallpaperScheduler.swift |
| `[D-display-uuid]` | spec/displays.md:108 "Display identity" | Displays are identified by their hardware UUID, so settings survive unplugging, reconnecting, and rearranging | DisplayIdentity.swift |
| `[D-doc-check]` | TESTING.md:219 "Rules" | A unit test checks the docs' tags and references, and keeps `docs/INDEX.md` current | DocIndex.swift |
| `[D-dock-while-open]` | spec/interface.md:94 "Dock icon and app menu" | Phases shows a Dock icon, and appears in the ⌘Tab switcher, only while its window is open | DockPresence.swift, OpenPhasesWindow.swift, PhasesApp.swift, WindowLayoutConfigurator.swift |
| `[D-duplicate-phase]` | spec/window.md:199 "Phases window (one window for everything)" | Duplicate makes a copy of a phase | Phase.swift, PhaseEditorRulesTests.swift, PhaseTests.swift, PhasesWindow.swift, WallpaperScheduler.swift |
| `[D-editor-checks]` | testing/phase-editor-checks.md:11 "Phase editor checks (draft 63)" | The redesigned phase editor is checked by hand before it merges | PhaseEditorTests.swift |
| `[D-editor-labels]` | spec/phase-editor.md:43 "Phase editor" | Row labels are plain words with no trailing "…" | EditorRow.swift |
| `[D-editor-layout]` | spec/phase-editor.md:17 "Phase editor" | The phase editor is a name row, one block of settings, then the images | EditorBox.swift, EditorRow.swift, PhaseEditor.swift |
| `[D-editor-popups]` | spec/phase-editor.md:176 "Phase editor" | The settings block's pop-up menus look like System Settings' own | PhaseEditor.swift, SettingsPopUp.swift, StartsRow.swift |
| `[D-fade-in]` | spec/transitions.md:77 "Transitions" | fading the new image in over the old one | CrossfadeController.swift |
| `[D-fake-photos]` | TEST-TOOLS.md:241 "Launch arguments" | never touch the Photos library (draft 54) | FakePhotosProvider.swift, ImageLibrary.swift, ImageSourcesSection.swift, PhasesApp.swift, PhasesUITests.swift, PhotosProvider.swift, PhotosSourcesTests.swift, TestImages.swift, UITestMode.swift |
| `[D-first-launch-shows-window]` | spec/interface.md:169 "Dock icon and app menu" | The first launch opens the window | FirstLaunch.swift, FirstLaunchTests.swift, FirstLaunchWindow.swift, MenuBarLabel.swift, ReopenHandler.swift, UITestMode.swift, WallpaperScheduler.swift |
| `[D-follow-links]` | spec/image-library.md:101 "Image library" | Symlinks and Finder aliases count as what they point to | FolderScan.swift, FolderScanTests.swift, ImageLibrary.swift, LibraryListing.swift |
| `[D-footer-ax-labels]` | spec/window.md:191 "Phases window (one window for everything)" | + and − carry explicit accessibility labels | ImageSourcesSection.swift, PhasesWindow.swift |
| `[D-grid-collapse-saved]` | spec/image-library.md:284 "Image library" | The collapsed headings are saved | GridCollapseTests.swift, GridOutline.swift, GridOutlineTests.swift, ImageLibrary.swift |
| `[D-grid-collapse]` | spec/image-library.md:210 "Image library" | Every heading in the grid can collapse | GridCollapseTests.swift, GridOutline.swift, GridOutlineTests.swift, ImageGrid.swift, ImageGridNavigation.swift, ImageGridNavigationTests.swift, ImageLibrary.swift, ImageSourcesTests.swift, PhasesApp.swift, SyntheticInput.swift |
| `[D-grid-one-tab-stop]` | spec/image-library.md:291 "Image library" | Keyboard: the thumbnail grid is one Tab stop | FocusTests.swift, GridCollapseTests.swift, GridOutline.swift, GridOutlineTests.swift, ImageGrid.swift, ImageGridNavigation.swift, ImageGridNavigationTests.swift, ImageSourcesTests.swift, PhotosProvider.swift, PhotosSourcesTests.swift |
| `[D-grid-release-on-close]` | spec/image-library.md:336 "Image library" | Closing the Phases window releases the grid's thumbnails | FocusTests.swift, PhasesWindow.swift, WindowLayoutConfigurator.swift |
| `[D-hands-on-checks]` | TESTING.md:252 "Hands-on checks" | Every check that drives the mouse and keyboard or touches the real wallpaper is a hands-on check, and any one of them can run on its own | main.swift |
| `[D-image-header]` | spec/phase-editor.md:238 "Phase editor" | The image header pins to the top of the editor while the grid scrolls | ImageGrid.swift, ImageHeader.swift, PhaseEditor.swift, PhaseEditorTests.swift |
| `[D-image-sources]` | spec/image-library.md:13 "Image library" | The library is a list of image sources | FolderScan.swift, GridOutline.swift, ImageGrid.swift, ImageLibrary.swift, ImageSource.swift, ImageSourceTests.swift, ImageSourcesSection.swift, ImageSourcesTests.swift, LibraryListing.swift, ListFooter.swift, TestImages.swift, UITestMode.swift |
| `[D-in-order-remembers]` | spec/schedule.md:62 "Core model: phases plus rotation" | In order remembers the last image it showed and moves to the next one | AppliedState.swift, FetchAhead.swift, FetchAheadTests.swift, InOrderPicker.swift, InOrderPickerTests.swift, WallpaperCheck.swift, WallpaperScheduler.swift |
| `[D-initial-focus-sidebar]` | spec/window.md:239 "Phases window (one window for everything)" | The sidebar list has keyboard focus when the window opens | FocusTests.swift, PhasesApp.swift, PhasesWindow.swift |
| `[D-input-click-state]` | TEST-TOOLS.md:130 "Input driver" | Mouse down, up and drag carry click state 1, a single click, the way a mouse sends them | SyntheticInput.swift |
| `[D-input-driver]` | TEST-TOOLS.md:23 "Input driver" | All mouse and keyboard driving goes through `PhasesUIDriver`'s `SyntheticInput` | Package.swift, SyntheticInput.swift, main.swift |
| `[D-input-lands]` | TESTING.md:281 "Hands-on checks" | Prove the input landed before trusting a result | main.swift |
| `[D-input-modifier-keys]` | TEST-TOOLS.md:52 "Input driver" | A modifier is pressed as a key of its own, down before the key it modifies and up after it, the way a keyboard sends it | SyntheticInput.swift |
| `[D-keep-display-settings]` | spec/displays.md:126 "Display identity" | Saved display settings are never pruned | PhaseEditorRulesTests.swift, WallpaperScheduler.swift |
| `[D-links-outside-refused]` | spec/sandbox.md:155 "What changes inside the sandbox" | Links and aliases that point outside the source folder can't be read in the sandbox | FolderScan.swift, FolderScanTests.swift, ImageLibrary.swift |
| `[D-location-on-demand]` | spec/schedule.md:147 "Location" | Uses Location Services | PhaseAvailability.swift, WallpaperScheduler.swift |
| `[D-location-privacy-note]` | spec/schedule.md:152 "Location" | The Location section always carries a note | SettingsView.swift |
| `[D-login-consent]` | spec/launch-and-quit.md:12 "Launch at login: explicit consent only" |  | LaunchAtLogin.swift, SettingsView.swift |
| `[D-low-memory-note]` | spec/transitions.md:46 "Transitions" | On a Mac with less than 16 GB of memory, Settings suggests turning transitions off | LowMemoryNote.swift, LowMemoryNoteTests.swift, MemoryUse.swift, SettingsView.swift, UITestMode.swift |
| `[D-memory-flat]` | spec/project.md:126 "Memory" | Memory doesn't build up with wallpaper changes |  |
| `[D-memory-in-about]` | spec/window.md:482 "Pause banner and Settings" | Memory | LowMemoryNote.swift, LowMemoryNoteTests.swift, MemoryUse.swift, SettingsView.swift |
| `[D-memory-protocol]` | testing/memory-checks.md:11 "Memory checks (draft 32; covers, draft 33)" | Memory is checked by hand, ten changes per run, at least two runs before a change and two after |  |
| `[D-menu-no-shortcuts]` | spec/interface.md:83 "Menu bar menu" | The current image's filename is not shown in the menu | MenuContent.swift |
| `[D-menu-pause-verb]` | spec/interface.md:64 "Menu bar menu" | Pause Wallpaper Changes | MenuContent.swift, PauseBanner.swift, WallpaperScheduler.swift |
| `[D-menu-status-header]` | spec/interface.md:45 "Menu bar menu" | Kept short | MenuContent.swift |
| `[D-menubar-icon-paused]` | spec/interface.md:36 "Icons" | While paused, for any reason, the icon shows a small pause badge | MenuBarLabel.swift, PauseBannerTests.swift |
| `[D-menubar-icon]` | spec/interface.md:27 "Icons" | Menu bar icon | MenuBarLabel.swift |
| `[D-missed-latest-only]` | spec/schedule.md:131 "Missed changes: sleep, wake, unlock" |  | ScheduleEngineTests.swift, WallpaperCheck.swift, WallpaperCheckTests.swift |
| `[D-name-row]` | spec/phase-editor.md:47 "Phase editor" | The name row | PhaseEditorTests.swift, PhaseNameRow.swift, PhasesApp.swift, SettingsView.swift, SyntheticInput.swift |
| `[D-new-phase-now]` | spec/window.md:155 "Phases window (one window for everything)" | A new phase starts at the current time | Phase.swift, PhaseTests.swift, WallpaperScheduler.swift |
| `[D-no-fade-cases]` | spec/transitions.md:367 "A change, step by step" | No fade (instant switch) when | CrossfadeController.swift, ReduceMotionNote.swift |
| `[D-no-focus-steal]` | spec/transitions.md:408 "A change, step by step" | Phases never activates itself to force a menu bar restyle | WallpaperSetter.swift |
| `[D-no-screenshots]` | spec/transitions.md:330 "A change, step by step" | The cover is drawn from the image file | CrossfadeController.swift |
| `[D-no-shape-matching]` | spec/displays.md:166 "Not included" | Automatic matching of images to each display's shape (portrait, ultrawide, standard) |  |
| `[D-notice-opens-window]` | spec/outside-change.md:69 "Wallpaper changed outside Phases" | Clicking the notification opens the Phases window | FirstLaunchWindow.swift, MenuBarLabel.swift, OpenPhasesWindow.swift, PauseNotifier.swift, WindowRequest.swift |
| `[D-one-window]` | spec/window.md:12 "Phases window (one window for everything)" | A single resizable window with a sidebar | App.swift, PhasesCommands.swift, PhasesWindow.swift |
| `[D-open-here]` | spec/interface.md:127 "Dock icon and app menu" | "Open Phases…" brings the window to the Space you're on; the Dock and ⌘Tab take you to the window | OpenPhasesWindow.swift, WindowSpaceMover.swift |
| `[D-order-row]` | spec/phase-editor.md:169 "Phase editor" | Show images | Phase.swift |
| `[D-outside-change-check]` | testing/outside-change-check.md:11 "Outside change check (draft 37)" | Pausing for a wallpaper picked elsewhere is checked by hand |  |
| `[D-outside-change-notice]` | spec/outside-change.md:63 "Wallpaper changed outside Phases" | Telling the user | MenuContent.swift, PauseNotifier.swift |
| `[D-outside-change-pauses]` | spec/outside-change.md:11 "Wallpaper changed outside Phases" | When someone picks a wallpaper in System Settings (or any other app), Phases pauses everything | CrossfadeController.swift, PauseReason.swift, RestorePoint.swift, WallpaperScheduler.swift |
| `[D-outside-change-rule]` | spec/outside-change.md:40 "Wallpaper changed outside Phases" | How a change is recognised | OutsideChangeRule.swift, OutsideChangeRuleTests.swift, WallpaperSetter.swift, WallpaperStoreWatcher.swift |
| `[D-own-images-no-fallback]` | spec/displays.md:102 "Per-display images" | If a display has its own selection but none of those images are available, that display keeps its current wallpaper; it does not fall bac… | WallpaperScheduler.swift |
| `[D-own-images-start-from-shared]` | spec/displays.md:92 "Per-display images" | Turning "Use different images on this display" on starts from a copy of the Shared selection | Phase.swift, PhaseEditorRulesTests.swift |
| `[D-pause-switch-disabled]` | spec/window.md:428 "Pause banner and Settings" | While the pause banner shows `[D-window-pause-banner]`, the switch is disabled | PauseBannerTests.swift, SettingsView.swift, WallpaperScheduler.swift |
| `[D-persistent-cover]` | spec/transitions.md:83 "The persistent cover" | After a crossfade, the cover stays up for as long as its Space is showing | CrossfadeController.swift |
| `[D-phase-actions]` | spec/window.md:212 "Phases window (one window for everything)" | Phase actions live in two places that list the same commands | PhasesWindow.swift |
| `[D-phase-cant-run]` | spec/schedule.md:189 "Location" | A phase that can't run is flagged in the sidebar | LocationProvider.swift, PhaseAvailability.swift, PhaseAvailabilityTests.swift, PhasesWindow.swift, WallpaperScheduler.swift |
| `[D-phase-status-inline]` | spec/phase-editor.md:218 "Phase editor" | Why a phase can't run shows under the row that fixes it | PhaseAvailability.swift, PhaseEditor.swift, PhaseEditorRulesTests.swift, StartReadout.swift |
| `[D-phase-turn-off]` | spec/schedule.md:218 "Location" | A phase can be turned off | Phase.swift, PhaseAvailability.swift, PhaseAvailabilityTests.swift, PhaseNameRow.swift, PhasesWindow.swift, WallpaperScheduler.swift |
| `[D-photos-cache]` | spec/photos.md:158 "Photos albums" | The photo cache | CrossfadeController.swift, ImageLibrary.swift, LibraryListing.swift, PhotoCache.swift, PhotoCacheRules.swift, PhotoCacheRulesTests.swift, WallpaperScheduler.swift, WallpaperStoreWatcher.swift |
| `[D-photos-changes]` | spec/photos.md:203 "Photos albums" | Album changes show up while Phases runs | ImageLibrary.swift, PhotoKitProvider.swift, PhotosProvider.swift, WallpaperScheduler.swift |
| `[D-photos-checks]` | testing/photos-checks.md:11 "Photos checks (draft 54)" | Real Photos behavior is checked by hand before merge #2 merges |  |
| `[D-photos-fetch-ahead]` | spec/photos.md:90 "Photos albums" | Phases fetches photos before they're needed, so scheduled changes still happen on time | ChangeRecord.swift, ChangeRecordTests.swift, FetchAhead.swift, FetchAheadTests.swift, ImageLibrary.swift, PhotoCache.swift, PhotoKitProvider.swift, WallpaperScheduler.swift |
| `[D-photos-names]` | spec/photos.md:57 "Photos albums" | A saved photo is named by its source, its album, and the photo's ID in the Photos library | FakePhotosProvider.swift, ImageLibrary.swift, ImageSource.swift, ImageSourceTests.swift, PhotosProvider.swift |
| `[D-photos-order]` | spec/photos.md:52 "Photos albums" | In order follows the album's own order | LibraryListing.swift, PhotosProvider.swift |
| `[D-photos-permission]` | spec/photos.md:185 "Photos albums" | Phases asks for Photos access the first time it's needed | ImageLibrary.swift, PhotoKitProvider.swift, PhotosAlbumSheet.swift, PhotosProvider.swift, PhotosSourcesTests.swift |
| `[D-photos-sources]` | spec/photos.md:15 "Photos albums" | A Photos album, or a folder of albums, can be an image source | ImageLibrary.swift, ImageSource.swift, ImageSourceTests.swift, ImageSourcesSection.swift, PhotoKitProvider.swift, PhotosAlbumSheet.swift, PhotosProvider.swift, PhotosSourcesTests.swift |
| `[D-photos-version]` | spec/photos.md:72 "Photos albums" | The wallpaper is the photo as it looks in Photos | PhotoCache.swift, PhotoCacheRules.swift, PhotoCacheRulesTests.swift, PhotoKitProvider.swift, PhotosProvider.swift |
| `[D-quit-confirm]` | spec/interface.md:218 "Dock icon and app menu" | Quit Phases (⌘Q) asks first | PhasesCommands.swift, QuitConfirmation.swift, SettingsView.swift, WallpaperScheduler.swift |
| `[D-record-after-wait]` | spec/photos.md:120 "Photos albums" | A change is saved only once it shows | ChangeRecord.swift, ChangeRecordTests.swift, WallpaperScheduler.swift |
| `[D-reduce-motion-note]` | spec/transitions.md:15 "Transitions" | Settings says when Reduce Motion turns transitions off | CrossfadeController.swift, ReduceMotionNote.swift, ReduceMotionNoteTests.swift, SettingsView.swift, WallpaperScheduler.swift |
| `[D-refs-by-id]` | SPEC.md:32 "Design decisions" | Cross-references use a `[D-…]` or `[Q-…]` tag or a section title, never a section number | DocIndex.swift |
| `[D-reopen-shows-window]` | spec/interface.md:149 "Dock icon and app menu" | Launching Phases while it's already running shows the window | App.swift, MenuBarLabel.swift, OpenPhasesWindow.swift, PhasesApp.swift, RelaunchTests.swift, ReopenHandler.swift, WindowRequest.swift |
| `[D-reset-on-quick-return]` | spec/transitions.md:155 "The persistent cover" | Left just after the set | CrossfadeController.swift |
| `[D-restore-file-check]` | spec/sandbox.md:137 "What changes inside the sandbox" | Restoring checks a file is gone before skipping it | RestorePoint.swift, SystemWallpaperCheck.swift, SystemWallpaperCheckTests.swift |
| `[D-restore-on-quit]` | spec/launch-and-quit.md:33 "Restore original wallpaper on quit" | App preference: Restore original wallpaper when quitting | SettingsView.swift, WallpaperCheckTests.swift, WallpaperScheduler.swift |
| `[D-rotation-row]` | spec/phase-editor.md:155 "Phase editor" | Change images | PhaseEditor.swift, PhaseEditorRulesTests.swift, PhaseEditorTests.swift, RotationChoice.swift |
| `[D-row-status-not-cause]` | spec/schedule.md:201 "Location" | The row shows the status; the editor shows the cause | PhaseAvailability.swift, PhaseAvailabilityTests.swift, PhasesWindow.swift |
| `[D-sandbox-entitlements]` | spec/sandbox.md:44 "Entitlements" | Only these, each for something Phases does | EntitlementsTests.swift, ImageLibrary.swift, SystemWallpaperInspector.swift, WallpaperStoreWatcher.swift |
| `[D-sandbox-settings-move]` | spec/sandbox.md:180 "Settings when switching to the sandboxed build" | Existing settings carry over, by moving |  |
| `[D-sandboxed]` | spec/sandbox.md:12 "Sandbox" | Phases runs in the macOS App Sandbox | CrossfadeController.swift, FolderScan.swift, ImageLibrary.swift, WallpaperScheduler.swift |
| `[D-scan-each-folder-once]` | spec/image-library.md:133 "Image library" | Each folder is scanned at most once | FolderScan.swift, FolderScanTests.swift, ImageLibrary.swift |
| `[D-scoped-bookmarks]` | spec/image-library.md:177 "Image library" | Source bookmarks are security-scoped | ImageLibrary.swift, ImageSource.swift, WallpaperScheduler.swift |
| `[D-screen-change-no-reroll]` | spec/displays.md:175 "When displays change" | When macOS reports a display change (connect, disconnect, resolution, arrangement, or anything else that changes screen geometry), Phases… | ChangeRecord.swift, ChangeRecordTests.swift, WallpaperCheck.swift, WallpaperCheckTests.swift, WallpaperScheduler.swift |
| `[D-settings-at-top]` | spec/window.md:121 "Phases window (one window for everything)" | "App" section | PhasesWindow.swift |
| `[D-settings-order]` | spec/window.md:448 "Pause banner and Settings" | Settings selected | SettingsView.swift |
| `[D-settings-pause-switch]` | spec/window.md:422 "Pause banner and Settings" | Settings starts with a Pause wallpaper changes switch | SettingsView.swift, WallpaperScheduler.swift |
| `[D-sharing-per-phase]` | spec/displays.md:137 "Displays sharing the Shared images" | A setting of each phase | DisplayTabs.swift, ImageHeader.swift, Phase.swift, PhaseEditorRulesTests.swift, SettingsView.swift, WallpaperScheduler.swift |
| `[D-sidebar-always-visible]` | spec/window.md:351 "Phases window (one window for everything)" | The sidebar can't be hidden | PhasesCommands.swift, PhasesUITests.swift, PhasesWindow.swift, SidebarTests.swift, WindowLayoutConfigurator.swift |
| `[D-sidebar-footer-style]` | spec/window.md:181 "Phases window (one window for everything)" | + / − layout matches System Settings | ImageSourcesSection.swift, ImageSourcesTests.swift, ListFooter.swift, PhasesWindow.swift |
| `[D-sidebar-footer-view]` | spec/window.md:232 "Phases window (one window for everything)" | The + / − buttons are their own view, bound to the sidebar selection, not inline in the window's body | PhaseListTests.swift, PhasesWindow.swift |
| `[D-sidebar-limits-watch]` | spec/window.md:365 "Phases window (one window for everything)" | The limits are watched and put back whenever SwiftUI changes them | PhasesUITests.swift, SidebarTests.swift, WindowLayoutConfigurator.swift |
| `[D-sidebar-width]` | spec/window.md:248 "Phases window (one window for everything)" | Sidebar width | PhasesApp.swift, PhasesUITests.swift, PhasesWindow.swift, WindowLayoutConfigurator.swift |
| `[D-single-timer]` | spec/project.md:109 "Platform notes and limitations" | Scheduling uses a single timer aimed at the next event (a change, or from draft 54 a photo fetch ahead of one `[D-photos-fetch-ahead]`), … | WallpaperScheduler.swift |
| `[D-source-location]` | spec/image-library.md:166 "Image library" | Each source remembers where its folder is in two ways | ImageLibrary.swift, ImageSource.swift, ImageSourceTests.swift, SourceLocation.swift |
| `[D-source-names]` | spec/image-library.md:144 "Image library" | A saved image is named by its source and its path within that source | FolderScan.swift, ImageLibrary.swift, ImageSource.swift, ImageSourceTests.swift, ImageSourcesTests.swift, LibraryListing.swift |
| `[D-start-readout]` | spec/phase-editor.md:141 "Phase editor" | A dawn or dusk phase says when it starts today | PhaseEditor.swift, PhaseEditorRulesTests.swift, StartReadout.swift |
| `[D-starter-phases]` | spec/schedule.md:34 "Core model: phases plus rotation" | A new user starts with three phases | Phase.swift, PhaseTests.swift |
| `[D-starts-row]` | spec/phase-editor.md:105 "Phase editor" | The Starts row reads as a sentence, so its controls change with the trigger | OffsetParts.swift, Phase.swift, PhaseEditorRulesTests.swift, PhaseEditorTests.swift, StartReadout.swift, StartsRow.swift |
| `[D-store-unreadable-safe]` | spec/sandbox.md:118 "What changes inside the sandbox" | "Couldn't read the store" is never taken for "no Aerials" | RestorePoint.swift, SystemWallpaperCheck.swift, SystemWallpaperCheckTests.swift, SystemWallpaperInspector.swift, WallpaperStoreWatcher.swift |
| `[D-tall-toolbar]` | spec/window.md:317 "Phases window (one window for everything)" | Full-height toolbar over the detail pane only | App.swift, AppearanceTests.swift, PauseBannerTests.swift, WindowLayoutConfigurator.swift |
| `[D-test-memory-size]` | TEST-TOOLS.md:293 "Launch arguments" | act as if the Mac had `<n>` GB of memory, when launched with `-PhasesUITestMemoryGB <n>` as well (a whole number of GB, 1024³ bytes each) | LowMemoryNoteTests.swift, MemoryUse.swift, PhasesApp.swift, UITestMode.swift |
| `[D-test-no-location-prompt]` | TEST-TOOLS.md:214 "Launch arguments" | Test launches can skip the location prompt | LocationProvider.swift |
| `[D-test-outside-change-now]` | TEST-TOOLS.md:277 "Launch arguments" | pause as if the wallpaper had just been changed in System Settings, at any moment, when the test posts the distributed notification `Phas… | PauseBannerTests.swift, PhasesApp.swift, UITestMode.swift, WallpaperScheduler.swift |
| `[D-test-paused-by-outside-change]` | TEST-TOOLS.md:269 "Launch arguments" | start paused as if the wallpaper had just been changed in System Settings, when launched with `-PhasesUITestPausedByOutsideChange YES` as… | PhasesApp.swift, UITestMode.swift, WallpaperScheduler.swift |
| `[D-tests-carry-tags]` | TESTING.md:216 "Rules" | Tests for a tagged decision carry its tag |  |
| `[D-tests-unhosted]` | TESTING.md:205 "Rules" | The tests never launch Phases | GridOutline.swift, LowMemoryNote.swift, Package.swift, PauseReason.swift, ReduceMotionNote.swift, SystemWallpaperCheck.swift |
| `[D-ui-menubar-wide]` | testing/interface-tests.md:107 "How the tests work" | Phases' menu bar item is only clicked on a display at least 1200 points wide | PhasesApp.swift |
| `[D-ui-test-build-pick]` | testing/interface-tests.md:70 "How the tests work" | The UI tests launch the newest Bitrig Debug build, by the time in its folder's name, and refuse it unless its build number matches the pr… | BuildPick.swift, BuildPickTests.swift, PhasesApp.swift |
| `[D-ui-test-ids]` | testing/interface-tests.md:117 "How the tests work" | Controls the tests use carry accessibility identifiers | DisplayTabsRow.swift, GridCollapseTests.swift, ImageGrid.swift, ImageHeader.swift, ImageSourcesSection.swift, PauseBanner.swift, PhaseNameRow.swift, PhasesApp.swift, PhasesWindow.swift, SettingsView.swift |
| `[D-ui-test-mode]` | TEST-TOOLS.md:221 "Launch arguments" | Test mode: one launch that touches nothing real | FirstLaunch.swift, GridCollapseTests.swift, ImageLibrary.swift, LocationProvider.swift, PhaseListTests.swift, PhasesApp.swift, PhasesUITests.swift, PhotoCache.swift, RestorePoint.swift, SavedLayout.swift, SettingsStore.swift, TestImages.swift, UITestMode.swift, WallpaperScheduler.swift, WallpaperSetter.swift |
| `[D-ui-test-runner]` | testing/interface-tests.md:55 "How the tests work" | The UI tests drive Phases through the Accessibility API, not XCUITest | Package.swift, PhasesApp.swift, PhasesUITests.swift, SyntheticInput.swift |
| `[D-undo-remove-source]` | spec/image-library.md:77 "Image library" | Removing a source can be undone | ImageLibrary.swift, ImageSourcesSection.swift, ImageSourcesTests.swift |
| `[D-version-in-settings]` | spec/window.md:476 "Pause banner and Settings" | About section | AppVersion.swift, AppVersionTests.swift, SettingsView.swift |
| `[D-window-helper-order]` | spec/window.md:340 "Phases window (one window for everything)" | One AppKit helper, in a fixed order | PhasesWindow.swift, SidebarTests.swift, WindowLayoutConfigurator.swift |
| `[D-window-min-size]` | spec/window.md:263 "Phases window (one window for everything)" | Minimum window size | App.swift, EditorRow.swift, PauseBannerTests.swift, PhasesUITests.swift, PhasesWindow.swift |
| `[D-window-pause-banner]` | spec/window.md:380 "Pause banner and Settings" | While Phases has paused itself for an outside change `[D-outside-change-pauses]`, a pause banner sits at the top of the detail pane | PauseBanner.swift, PauseBannerTests.swift, PauseReason.swift, PauseReasonTests.swift, PhasesWindow.swift, SettingsView.swift, WallpaperScheduler.swift, WindowLayoutConfigurator.swift |
| `[D-window-title-phases]` | spec/window.md:320 "Phases window (one window for everything)" | The toolbar title is always **Phases**, the window's name; what's selected is named by the pane's own header: the phase editor's name row… | PhaseEditor.swift, SettingsView.swift |
| `[D-xcode-project]` | spec/project.md:12 "Project and bundle ID" | Phases is an Xcode project | AppVersion.swift, AppVersionTests.swift |

## Quirks `[Q-…]`

| Tag | Where | Says | Cited in code |
|---|---|---|---|
| `[Q-accessory-focus-handoff]` | ERRATA.md:529 "Window, sidebar, and toolbar (SwiftUI and AppKit)" | Switching back to accessory hands focus to the most recently used app, even on another Space | FocusHandoff.swift, WindowLayoutConfigurator.swift |
| `[Q-activate-switches-space]` | ERRATA.md:535 "Window, sidebar, and toolbar (SwiftUI and AppKit)" | Activating an app whose only window is on another Space switches to that Space, whatever triggered it | OpenPhasesWindow.swift, WindowSpaceMover.swift |
| `[Q-app-intents-metadata]` | ERRATA.md:612 "Build (Xcode)" | Xcode runs its App Intents metadata step on every app build and warns when the app doesn't use App Intents (Xcode 27.3 beta, 27C5035i) |  |
| `[Q-bartender-menubar]` | ERRATA.md:155 "Wallpaper and menu bar (macOS)" | Bartender (menu bar manager) caused additional odd menu bar behavior during testing | PhasesApp.swift |
| `[Q-bitrig-build-dates]` | TEST-TOOLS.md:392 "Tools" | File dates in Bitrig's Builds folder don't say which build is newest |  |
| `[Q-bitrig-test-targets]` | TEST-TOOLS.md:344 "Tools" | `bitrig test` doesn't see test targets in Project.json projects | Package.swift |
| `[Q-borderless-pressed-state]` | ERRATA.md:507 "Window, sidebar, and toolbar (SwiftUI and AppKit)" | Borderless buttons show their pressed state only by darkening the icon (macOS 27) | PhasesWindow.swift |
| `[Q-closed-window-keeps-focus]` | TEST-TOOLS.md:469 "Tools" | Closing the Phases window only hides it; on reopen it still has whatever had focus, with the text cursor and selection where they were (m… |  |
| `[Q-closed-window-keeps-space]` | ERRATA.md:544 "Window, sidebar, and toolbar (SwiftUI and AppKit)" | A closed SwiftUI `Window` comes back on the Space it was closed on | WindowSpaceMover.swift |
| `[Q-container-closed-to-tests]` | TEST-TOOLS.md:407 "Tools" | The sandboxed Phases can't read the harness's temporary folders, and the harness can't write into Phases' container | TestImages.swift |
| `[Q-cover-image-copied]` | ERRATA.md:238 "Wallpaper and menu bar (macOS)" | Core Animation copies every CGImage set as a layer's `contents`, a full-screen copy per cover, and the copy outlives the window; an IOSur… | CoverSurface.swift |
| `[Q-default-focus-loses]` | ERRATA.md:487 "Window, sidebar, and toolbar (SwiftUI and AppKit)" | `.defaultFocus` on the sidebar List doesn't stop macOS from focusing the first text field when the window opens (macOS 27) | FocusTests.swift, PhasesWindow.swift |
| `[Q-empty-toolbar-66pt]` | ERRATA.md:420 "Window, sidebar, and toolbar (SwiftUI and AppKit)" | An empty unified `NSToolbar` makes the title area 66 pt tall (macOS 27) | AppearanceTests.swift, WindowLayoutConfigurator.swift |
| `[Q-fixed-size-text-rigid-split]` | ERRATA.md:445 "Window, sidebar, and toolbar (SwiftUI and AppKit)" | Text with `.fixedSize(horizontal: false, vertical: true)` in a `NavigationSplitView` column can make the whole split view a fixed height … | PauseBanner.swift, PhasesWindow.swift |
| `[Q-iosurface-color-tag]` | ERRATA.md:283 "Wallpaper and menu bar (macOS)" | Core Animation treats an IOSurface with no color space attached as already in the display's color space (macOS 27.2) | CoverSurface.swift |
| `[Q-launch-activate-refused]` | TEST-TOOLS.md:422 "Tools" | A menu bar app launched in the background can't bring itself to the front with `NSApp.activate()` (macOS 27.2) | FirstLaunchWindow.swift, MenuBarLabel.swift, ReopenHandler.swift |
| `[Q-lazy-grid-tab]` | ERRATA.md:498 "Window, sidebar, and toolbar (SwiftUI and AppKit)" | Tab can't reach buttons in a `LazyVGrid` that haven't been created yet, and the Form doesn't scroll to follow Tab (macOS 27) | FocusTests.swift, ImageGrid.swift |
| `[Q-list-row-padding]` | ERRATA.md:432 "Window, sidebar, and toolbar (SwiftUI and AppKit)" | The sidebar list adds about 14–16 pt of its own padding inside a row's insets (macOS 27) | PhasesWindow.swift |
| `[Q-menubar-bg-follows-window]` | ERRATA.md:49 "Wallpaper and menu bar (macOS)" | The menu bar's background restyles when the window under it changes, not when the wallpaper changes (macOS 27.2) |  |
| `[Q-menubar-blank]` | ERRATA.md:141 "Wallpaper and menu bar (macOS)" | The menu bar blanks for about 0.1 s when the wallpaper changes |  |
| `[Q-menubar-reads-wallpaper]` | ERRATA.md:135 "Wallpaper and menu bar (macOS)" | macOS picks the menu bar's text color and shadow from the actual wallpaper, ignoring windows above it | CrossfadeController.swift |
| `[Q-menubar-restyle-on-app-switch]` | ERRATA.md:148 "Wallpaper and menu bar (macOS)" | macOS sometimes doesn't restyle the menu bar after a wallpaper change until the frontmost app changes (macOS 27.0.1) | WallpaperSetter.swift |
| `[Q-new-space-copies-entry]` | ERRATA.md:187 "Wallpaper and menu bar (macOS)" | A new Space's store entries are copies of the display's, old "last set" time included, and Space entries are never removed (macOS 27.2) | OutsideChangeRule.swift |
| `[Q-no-items-no-toolbar]` | ERRATA.md:414 "Window, sidebar, and toolbar (SwiftUI and AppKit)" | A SwiftUI window with no toolbar items gets no toolbar at all, so `.windowToolbarStyle(.unified)` has no effect and the title bar stays s… | App.swift, AppearanceTests.swift, WindowLayoutConfigurator.swift |
| `[Q-opaque-cover-freezes-menubar]` | ERRATA.md:61 "Wallpaper and menu bar (macOS)" | A fully opaque full-screen cover stops the menu bar restyling for new wallpapers; a 99% opaque one doesn't (macOS 27.2) | CrossfadeController.swift |
| `[Q-regular-activation-menubar]` | ERRATA.md:520 "Window, sidebar, and toolbar (SwiftUI and AppKit)" | Switching from accessory to regular and activating in the same pass can leave the app frontmost without its menu bar | DockPresence.swift, OpenPhasesWindow.swift |
| `[Q-reopen-ignores-closed-window]` | ERRATA.md:560 "Window, sidebar, and toolbar (SwiftUI and AppKit)" | Launching Phases while it runs activates it but shows nothing if the window is closed or was never opened (macOS 27.2, SwiftUI `Window` w… | RelaunchTests.swift, ReopenHandler.swift |
| `[Q-safe-area-inset-refresh]` | ERRATA.md:439 "Window, sidebar, and toolbar (SwiftUI and AppKit)" | Content in a List's `.safeAreaInset` may not refresh when the parent view's state changes (macOS) | PauseBanner.swift, PhaseListTests.swift, PhasesWindow.swift |
| `[Q-sandbox-container-home]` | ERRATA.md:342 "Sandbox (macOS)" | In the sandbox, "home" is the container | SystemWallpaperCheck.swift, SystemWallpaperCheckTests.swift, SystemWallpaperInspector.swift, WallpaperStoreWatcher.swift |
| `[Q-sandbox-set-unreadable-file]` | ERRATA.md:377 "Sandbox (macOS)" | macOS sets a wallpaper file that the sandboxed app can't read | SystemWallpaperCheck.swift |
| `[Q-sandbox-store-exception]` | ERRATA.md:353 "Sandbox (macOS)" | The wallpaper store needs a temporary exception, and the exception needs a development team | SystemWallpaperInspector.swift, WallpaperStoreWatcher.swift |
| `[Q-screen-params-notification]` | ERRATA.md:158 "Wallpaper and menu bar (macOS)" | `NSApplication.didChangeScreenParametersNotification` fires for more than display changes (macOS 27.2) | CrossfadeController.swift, WallpaperScheduler.swift |
| `[Q-set-target-decided-late]` | ERRATA.md:98 "Wallpaper and menu bar (macOS)" | A wallpaper set made early in a Space swipe can land on the arrival Space, even while the departing Space's windows still report `isOnAct… | CrossfadeController.swift |
| `[Q-settings-popup-look]` | ERRATA.md:573 "Window, sidebar, and toolbar (SwiftUI and AppKit)" | SwiftUI draws System Settings' pop-up look (no box, the chevron in a circle) only for a menu picker inside a grouped `Form` (macOS 27.2) | SettingsPopUp.swift |
| `[Q-sidebar-collapse]` | ERRATA.md:407 "Window, sidebar, and toolbar (SwiftUI and AppKit)" | A sidebar's minimum width doesn't stop it collapsing, and SwiftUI can't make it non-collapsible | PhasesWindow.swift, SidebarTests.swift, WindowLayoutConfigurator.swift |
| `[Q-space-notify-after-swipe]` | ERRATA.md:82 "Wallpaper and menu bar (macOS)" | macOS announces a Space change only after the swipe, about 0.9–1.1 s after the key press, and a wallpaper set reaches only the Space show… | CrossfadeController.swift |
| `[Q-split-item-rewrite]` | ERRATA.md:391 "Window, sidebar, and toolbar (SwiftUI and AppKit)" | `NavigationSplitView` rewrites its sidebar's AppKit split view item some time after the window opens, ignoring `.navigationSplitViewColum… | PhasesUITests.swift, PhasesWindow.swift, SidebarTests.swift, WindowLayoutConfigurator.swift |
| `[Q-store-kind-lastset]` | ERRATA.md:198 "Wallpaper and menu bar (macOS)" | In the wallpaper store, `LastUse` says nothing about which entry is showing; `LastSet` marks the latest pick (macOS 27.2) | SystemWallpaperCheck.swift, SystemWallpaperCheckTests.swift, SystemWallpaperInspector.swift |
| `[Q-system-events-ax]` | TEST-TOOLS.md:319 "Tools" | System Events (AppleScript) doesn't report SwiftUI button descriptions (macOS 27) | AXNode.swift, PhasesWindow.swift |
| `[Q-tint-on-highlight]` | ERRATA.md:463 "Window, sidebar, and toolbar (SwiftUI and AppKit)" | On a selected sidebar row, accent-colored text vanishes into the colored highlight, and SwiftUI doesn't tell the row it's on one (macOS 2… | PhasesWindow.swift, SidebarHighlight.swift |
| `[Q-undo-menu-ax]` | TEST-TOOLS.md:328 "Tools" | Edit › Undo and Redo, read through the AX API, don't match what the menu shows, and a menu that wasn't opened by a click keeps stale enab… | ImageSourcesTests.swift, PhasesApp.swift |
| `[Q-view-menu-fullscreen]` | ERRATA.md:550 "Window, sidebar, and toolbar (SwiftUI and AppKit)" | Emptying SwiftUI's View menu doesn't remove it: macOS adds Enter Full Screen, so a one-item View menu remains (macOS 27.2) | PhasesCommands.swift |
| `[Q-wallpaper-motion-delay]` | ERRATA.md:28 "Wallpaper and menu bar (macOS)" | After an app sets the wallpaper, macOS plays about 0.13 s of its own motion (a shift that settles back) somewhere within the next 1.5 s (… | CrossfadeController.swift |
| `[Q-wallpaper-store]` | ERRATA.md:166 "Wallpaper and menu bar (macOS)" | No public API reports a wallpaper picked in System Settings, and `desktopImageURL(for:)` can't be trusted to name it (macOS 27.2) | SystemWallpaperCheck.swift |

## Learnings `[L-…]`

| Tag | Where | Says | Cited in code |
|---|---|---|---|
| `[L-aerial-kind-lastuse]` | LEARNINGS.md:350 "Photos library (issue #33)" (pointer) | *Pointer:* Promoted to `[Q-store-kind-lastset]` (2026-11-27) |  |
| `[L-backdrop-private-store]` | EXPERIMENTS.md:45 "Notes outside any experiment"<br>LEARNINGS.md:77 "Wallpaper, covers, and the menu bar" | Backdrop (Cindori) puts video on the lock screen by registering entries in macOS's private wallpaper store |  |
| `[L-background-prominence-mac-list]` | LEARNINGS.md:137 "Sidebar rows" (pointer)<br>experiments/X-active-badge-highlight.md:30 "`[X-active-badge-highlight]` The Active badge on the selection highlight" (pointer) | *Pointer:* Promoted to `[Q-tint-on-highlight]` (2026-11-06) |  |
| `[L-classic-mac-layout]` | LEARNINGS.md:177 "UI mockup (issues #2, #3, #26, #27)"<br>experiments/X-ui-mockup.md:23 "`[X-ui-mockup]` Interface mockup" | Old-style Mac layouts were tried and dropped |  |
| `[L-click-state-not-needed]` | LEARNINGS.md:448 "Test tools" | Phases' clicks work with click state 0 on mouse up; the driver doesn't need to set it | SyntheticInput.swift |
| `[L-closed-menu-stale]` | LEARNINGS.md:394 "Image sources (issue #33, merge 1)"<br>experiments/X-33-image-sources.md:30 "`[X-33-image-sources]` Image sources: findings from merge 1 of issue #33" | A closed menu's items, read through AX, keep the title and enabled state from when the menu last opened |  |
| `[L-convert-xcode-project]` | LEARNINGS.md:232 "Other investigations" | `bitrig convert-to-xcode-project` carried every Project.json setting over, added two sandbox build settings, and lost team signing |  |
| `[L-cover-all-spaces]` | LEARNINGS.md:31 "Wallpaper, covers, and the menu bar"<br>experiments/X-persistent-cover.md:46 "`[X-persistent-cover]` Keeping a cover up between changes" | A cover that joins all Spaces shows on every Space and in Mission Control, and slides with each Space like a real wallpaper |  |
| `[L-cover-alpha-later]` | EXPERIMENTS.md:130 "Still open"<br>LEARNINGS.md:402 "Open questions" | Could the 99% cover go to 100% once the menu bar has restyled, and does it matter? |  |
| `[L-cover-check-driving]` | TEST-TOOLS.md:539 "Driving and measuring the Mac in tests" | What the 2026-11-03 cover checks needed |  |
| `[L-cover-memory]` | LEARNINGS.md:47 "Wallpaper, covers, and the menu bar"<br>experiments/X-persistent-cover.md:80 "`[X-persistent-cover]` Keeping a cover up between changes" | One full-screen cover image cost about 23 MB, held about three times over, and the spike leaked on every change |  |
| `[L-cover-own-space]` | LEARNINGS.md:58 "Wallpaper, covers, and the menu bar"<br>experiments/X-persistent-cover.md:138 "`[X-persistent-cover]` Keeping a cover up between changes" | A cover that stays on its own Space can be removed unseen when you leave it |  |
| `[L-cover-settle-delay]` | LEARNINGS.md:82 "Wallpaper, covers, and the menu bar" | Before draft 33, the cover came off 1.5 s after the set, clearing macOS's motion at 0.55–0.65 s; 0.5 s brought the twitch back |  |
| `[L-cover-three-displays]` | LEARNINGS.md:54 "Wallpaper, covers, and the menu bar"<br>experiments/X-persistent-cover.md:123 "`[X-persistent-cover]` Keeping a cover up between changes" | The 99% cover held up on three displays |  |
| `[L-defaults-container-blocked]` | LEARNINGS.md:242 "Other investigations" | From Bitrig's shell, `defaults` can't read a sandboxed app's container: `defaults export` for the old ID wrote an empty plist (42 bytes, … |  |
| `[L-desktop-through-cover]` | LEARNINGS.md:41 "Wallpaper, covers, and the menu bar"<br>experiments/X-persistent-cover.md:66 "`[X-persistent-cover]` Keeping a cover up between changes" | Desktop icons, widgets, the desktop menu, and click-to-show-desktop all work through a cover |  |
| `[L-detail-scroll-short]` | LEARNINGS.md:461 "Test tools" | In a 645 pt tall window, the detail pane hardly scrolls: the image grid's first row stays below the window's bottom edge |  |
| `[L-diagnostics-switch-saved]` | LEARNINGS.md:352 "Photos library (issue #33)" | Phases' saved `PhasesDiagnostics` switch can be on while `defaults` in Bitrig's shell says the domain doesn't exist |  |
| `[L-divider-drag-right]` | LEARNINGS.md:418 "Test tools" | In the first fast-suite run on the sandboxed build, dragging the sidebar divider far right left the sidebar at 239.5 pt, not 320 |  |
| `[L-first-launch-activation]` | experiments/X-first-launch-activation.md:23 "`[X-first-launch-activation]` First-launch window staying behind"<br>LEARNINGS.md:230 "Other investigations" (pointer) | First-launch window staying behind: promoted to `[Q-launch-activate-refused]` (2026-11-06) |  |
| `[L-hdr-wallpaper]` | LEARNINGS.md:221 "Other investigations"<br>experiments/X-hdr-wallpaper.md:23 "`[X-hdr-wallpaper]` HDR photos as wallpaper" | macOS shows an HDR photo as wallpaper in SDR | CoverSurface.swift |
| `[L-lockscreen-uses-real-wallpaper]` | LEARNINGS.md:35 "Wallpaper, covers, and the menu bar"<br>experiments/X-persistent-cover.md:55 "`[X-persistent-cover]` Keeping a cover up between changes" | The lock screen and login window show the real wallpaper, never an app's drawing |  |
| `[L-login-dims-wallpaper]` | LEARNINGS.md:38 "Wallpaper, covers, and the menu bar"<br>experiments/X-persistent-cover.md:61 "`[X-persistent-cover]` Keeping a cover up between changes" | At logout macOS redraws the wallpaper, slightly darkened, with a twitch |  |
| `[L-main-memory]` | LEARNINGS.md:96 "Memory"<br>experiments/X-memory.md:41 "`[X-memory]` Where Phases' memory goes" | `main` at 179 MB with the window closed was mostly crossfade images plus the window's lasting cost |  |
| `[L-mem-ca-copy-test]` | ERRATA.md:247 "Wallpaper and menu bar (macOS)"<br>LEARNINGS.md:105 "Memory" (pointer)<br>experiments/X-memory.md:94 "`[X-memory]` Where Phases' memory goes" (pointer) | Core Animation copied every CGImage we gave it, whatever its format; an IOSurface it used as is |  |
| `[L-mem-ca-copy]` | LEARNINGS.md:103 "Memory"<br>experiments/X-memory.md:72 "`[X-memory]` Where Phases' memory goes" | Core Animation kept its own full-screen copy of each cover image, outliving the window |  |
| `[L-mem-cover-windows-freed]` | LEARNINGS.md:101 "Memory"<br>experiments/X-memory.md:67 "`[X-memory]` Where Phases' memory goes" | `main`'s cover windows were freed after each fade |  |
| `[L-mem-decode]` | LEARNINGS.md:115 "Memory"<br>experiments/X-memory.md:148 "`[X-memory]` Where Phases' memory goes" | Each cover also decoded the file at full size first: a peak, purged within 40 s |  |
| `[L-mem-draft33-runs]` | LEARNINGS.md:130 "Memory"<br>experiments/X-memory.md:247 "`[X-memory]` Where Phases' memory goes" | **Draft 33's persistent covers passed every |  |
| `[L-mem-fix-ideas]` | LEARNINGS.md:124 "Memory"<br>experiments/X-memory.md:171 "`[X-memory]` Where Phases' memory goes" | The agreed fix order: tagged IOSurface covers, decode once, release the grid, measure ten changes per run |  |
| `[L-mem-fix-runs]` | LEARNINGS.md:127 "Memory"<br>experiments/X-memory.md:193 "`[X-memory]` Where Phases' memory goes" | The fix held covers flat (2–3 MB over ten changes); the window still failed its check, and the grid isn't most of the window's cost |  |
| `[L-mem-freed-held]` | LEARNINGS.md:112 "Memory"<br>experiments/X-memory.md:140 "`[X-memory]` Where Phases' memory goes" | Freed full-screen buffers stayed in the process for minutes and counted in `footprint` |  |
| `[L-mem-iosurface-color]` | ERRATA.md:290 "Wallpaper and menu bar (macOS)"<br>LEARNINGS.md:106 "Memory" (pointer)<br>experiments/X-memory.md:95 "`[X-memory]` Where Phases' memory goes" (pointer) | An IOSurface needs its color space attached, or colors come out wrong; attached, it matches the CGImage and still isn't copied |  |
| `[L-mem-no-upscale]` | LEARNINGS.md:110 "Memory"<br>experiments/X-memory.md:135 "`[X-memory]` Where Phases' memory goes" | `loadImage` never scales an image up |  |
| `[L-mem-pressure-relief]` | LEARNINGS.md:107 "Memory"<br>experiments/X-memory.md:96 "`[X-memory]` Where Phases' memory goes" | `malloc_zone_pressure_relief` released nothing |  |
| `[L-mem-reconcile]` | LEARNINGS.md:122 "Memory"<br>experiments/X-memory.md:164 "`[X-memory]` Where Phases' memory goes" | The mechanisms above account for the earlier figures |  |
| `[L-mem-thumbnails]` | LEARNINGS.md:120 "Memory"<br>experiments/X-memory.md:162 "`[X-memory]` Where Phases' memory goes" | Thumbnails are small (4–9 MB for 22 images) |  |
| `[L-mem-timeline]` | LEARNINGS.md:99 "Memory"<br>experiments/X-memory.md:58 "`[X-memory]` Where Phases' memory goes" | Footprint rose and fell with crossfades; not a steady leak |  |
| `[L-mem-window]` | LEARNINGS.md:117 "Memory"<br>experiments/X-memory.md:154 "`[X-memory]` Where Phases' memory goes" | Opening the window once added about 25 MB that stayed after closing |  |
| `[L-memory-tools]` | TEST-TOOLS.md:497 "Driving and measuring the Mac in tests" | Measuring memory |  |
| `[L-menu-label-dead-zones]` | LEARNINGS.md:188 "UI mockup (issues #2, #3, #26, #27)" | A SwiftUI `Menu` drawn as a custom pop-up (`.menuStyle(.button)`, `.buttonStyle(.plain)`, hover box drawn outside it) had dead zones and … |  |
| `[L-menubar-launcher-setting]` | LEARNINGS.md:213 "Other investigations"<br>experiments/X-menubar-launcher-setting.md:22 "`[X-menubar-launcher-setting]` Missing menu bar icon under Bitrig" | A Phases launched by Bitrig follows Bitrig's switch in System Settings → Menu Bar |  |
| `[L-menubar-lazy-restyle]` | LEARNINGS.md:50 "Wallpaper, covers, and the menu bar"<br>experiments/X-persistent-cover.md:107 "`[X-persistent-cover]` Keeping a cover up between changes" | macOS sometimes leaves menu bar text the wrong colour with no cover involved; a click in the menu bar corrects it |  |
| `[L-menubar-overflow]` | LEARNINGS.md:217 "Other investigations"<br>experiments/X-menubar-overflow.md:26 "`[X-menubar-overflow]` Menu bar overflow and the test harness" | On macOS 27.2 a crowded menu bar hides Phases' icon behind a chevron, still reachable; macOS 26 untested |  |
| `[L-misfire-not-seen]` | LEARNINGS.md:70 "Wallpaper, covers, and the menu bar"<br>experiments/X-set-target-read.md:52 "`[X-set-target-read]` Which Space a set reaches during a swipe" | With `[D-reset-on-quick-return]` in, the misfire didn't happen in 24 trials |  |
| `[L-mock-known-displays]` | LEARNINGS.md:183 "UI mockup (issues #2, #3, #26, #27)"<br>experiments/X-ui-mockup.md:46 "`[X-ui-mockup]` Interface mockup" | The known-displays list grows without bound; |  |
| `[L-motion-waits-for-reveal]` | LEARNINGS.md:27 "Wallpaper, covers, and the menu bar"<br>experiments/X-persistent-cover.md:35 "`[X-persistent-cover]` Keeping a cover up between changes" | macOS seems to hold its wallpaper-change motion until the new wallpaper is first visible |  |
| `[L-nas-bookmark-rename]` | LEARNINGS.md:390 "Image sources (issue #33, merge 1)"<br>experiments/X-33-image-sources.md:20 "`[X-33-image-sources]` Image sources: findings from merge 1 of issue #33" | A security-scoped bookmark to a folder on a file server doesn't follow a rename; one to a local folder does |  |
| `[L-new-space-pauses]` | LEARNINGS.md:204 "Other investigations"<br>experiments/X-new-space-pauses.md:23 "`[X-new-space-pauses]` A new Space read as an outside change" | A new Space's store entries are copies, which read as outside changes | OutsideChangeRuleTests.swift |
| `[L-no-fullscreen-apps]` | TEST-TOOLS.md:555 "Driving and measuring the Mac in tests" | Activity Monitor doesn't support full screen (it only zooms); use Calendar to test full screen |  |
| `[L-notice-click-launches-copy]` | LEARNINGS.md:168 "Notification clicks"<br>experiments/X-notice-click.md:19 "`[X-notice-click]` What a click on the pause notification does" | Under development, a click on the pause notification can launch a second, differently registered copy of Phases, because `usernoted` brin… |  |
| `[L-nswindow-screen-rect]` | TEST-TOOLS.md:487 "Driving and measuring the Mac in tests" | `NSWindow(contentRect:…, screen:)` reads the rect relative to that screen, not in global coordinates |  |
| `[L-opaque-cover-freezes-menubar]` | ERRATA.md:66 "Wallpaper and menu bar (macOS)"<br>LEARNINGS.md:30 "Wallpaper, covers, and the menu bar" (pointer)<br>experiments/X-persistent-cover.md:45 "`[X-persistent-cover]` Keeping a cover up between changes" (pointer) | A fully opaque full-screen cover stops the menu bar restyling for new wallpapers; a 99% opaque one doesn't |  |
| `[L-outside-change-hidden]` | LEARNINGS.md:44 "Wallpaper, covers, and the menu bar"<br>experiments/X-persistent-cover.md:76 "`[X-persistent-cover]` Keeping a cover up between changes" | A wallpaper set by anything else while a cover is up is hidden by the cover |  |
| `[L-pause-banner-above-window]` | LEARNINGS.md:159 "Pause banner"<br>experiments/X-pause-banner-shift.md:110 "`[X-pause-banner-shift]` Window content shifted up while paused" | The columns were placed above the window while scroll positions were normal |  |
| `[L-pause-banner-inset]` | LEARNINGS.md:149 "Pause banner"<br>experiments/X-pause-banner-shift.md:30 "`[X-pause-banner-shift]` Window content shifted up while paused" | A top `.safeAreaInset` banner seemed to shift the window and stop following the pause |  |
| `[L-pause-banner-rigid-split]` | LEARNINGS.md:162 "Pause banner" (pointer)<br>experiments/X-pause-banner-shift.md:131 "`[X-pause-banner-shift]` Window content shifted up while paused" (pointer) | *Pointer:* Promoted to | PauseBannerTests.swift |
| `[L-pause-banner-runs]` | LEARNINGS.md:152 "Pause banner"<br>experiments/X-pause-banner-shift.md:53 "`[X-pause-banner-shift]` Window content shifted up while paused" | The UI tests didn't reproduce the author's shift; toolbar room arrives about 0.12 s after the first layout |  |
| `[L-pause-banner-stack-still-shifts]` | LEARNINGS.md:156 "Pause banner"<br>experiments/X-pause-banner-shift.md:87 "`[X-pause-banner-shift]` Window content shifted up while paused" | Moving the banner into a stack didn't fix the shift; the sidebar moved too | WindowLayoutConfigurator.swift |
| `[L-photos-album-order]` | LEARNINGS.md:328 "Photos library (issue #33)"<br>experiments/X-33-photokit.md:91 "`[X-33-photokit]` Photos library from a not-sandboxed Phases (round A)" | The default fetch follows the album's own order | PhotoKitProvider.swift |
| `[L-photos-bitrig-vs-installed]` | LEARNINGS.md:250 "Other investigations" | Photos access can read "blocked" in the app while System Settings shows Phases allowed, when a Bitrig build runs alongside an installed c… |  |
| `[L-photos-deleted-album-race]` | LEARNINGS.md:383 "Photos library (issue #33)"<br>experiments/X-33-photos-checks.md:75 "`[X-33-photos-checks]` Merge #2 Photos checks" | A photo from an album being deleted was set as the wallpaper |  |
| `[L-photos-formats-check]` | LEARNINGS.md:380 "Photos library (issue #33)"<br>experiments/X-33-photos-checks.md:67 "`[X-33-photos-checks]` Merge #2 Photos checks" | Edited, Live, ProRAW+HEIC, and DSLR RAW photos all showed the way Photos shows them |  |
| `[L-photos-grant-needs-relaunch]` | LEARNINGS.md:368 "Photos library (issue #33)"<br>experiments/X-33-photos-checks.md:25 "`[X-33-photos-checks]` Merge #2 Photos checks" | Allowing Phases in System Settings › Photos didn't reach a running Phases; a relaunch did |  |
| `[L-photos-grant-per-build]` | LEARNINGS.md:372 "Photos library (issue #33)"<br>experiments/X-33-photos-checks.md:37 "`[X-33-photos-checks]` Merge #2 Photos checks" | Each Bitrig build loses the Photos grant |  |
| `[L-photos-ids-stable]` | LEARNINGS.md:346 "Photos library (issue #33)"<br>experiments/X-33-sandbox.md:88 "Round B: sandboxed (2026-11-12, macOS 27.2)" | Photo IDs held across builds and the sandbox |  |
| `[L-photos-new-build-asks]` | LEARNINGS.md:340 "Photos library (issue #33)"<br>experiments/X-33-sandbox.md:73 "Round B: sandboxed (2026-11-12, macOS 27.2)" | A new build asks for Photos again |  |
| `[L-photos-offline-check]` | LEARNINGS.md:376 "Photos library (issue #33)"<br>experiments/X-33-photos-checks.md:51 "`[X-33-photos-checks]` Merge #2 Photos checks" | Offline, the fallback worked, but kept landing on the same photo |  |
| `[L-photos-x0-paths]` | LEARNINGS.md:306 "Photos library (issue #33)"<br>experiments/X-33-photokit.md:36 "`[X-33-photokit]` Photos library from a not-sandboxed Phases (round A)" | Not sandboxed, every way of finding home agrees |  |
| `[L-photos-x1-permission]` | LEARNINGS.md:310 "Photos library (issue #33)"<br>experiments/X-33-photokit.md:40 "`[X-33-photokit]` Photos library from a not-sandboxed Phases (round A)" | The Photos prompt worked from the probe launch |  |
| `[L-photos-x2-albums]` | LEARNINGS.md:313 "Photos library (issue #33)"<br>experiments/X-33-photokit.md:45 "`[X-33-photokit]` Photos library from a not-sandboxed Phases (round A)" | PhotoKit lists the author's albums and folders of albums in sidebar order, nested |  |
| `[L-photos-x3-download]` | LEARNINGS.md:317 "Photos library (issue #33)"<br>experiments/X-33-photokit.md:55 "`[X-33-photokit]` Photos library from a not-sandboxed Phases (round A)" | iCloud-only photos fail fast offline and download quickly online |  |
| `[L-photos-x4-cache-wallpaper]` | LEARNINGS.md:320 "Photos library (issue #33)"<br>experiments/X-33-photokit.md:74 "`[X-33-photokit]` Photos library from a not-sandboxed Phases (round A)" | A file in `~/Library/Caches` works as a wallpaper |  |
| `[L-photos-x5-observer]` | LEARNINGS.md:323 "Photos library (issue #33)"<br>experiments/X-33-photokit.md:84 "`[X-33-photokit]` Photos library from a not-sandboxed Phases (round A)" | The change observer fires while Phases is in the background | ImageLibrary.swift |
| `[L-photos-x6-ids]` | LEARNINGS.md:325 "Photos library (issue #33)"<br>experiments/X-33-photokit.md:88 "`[X-33-photokit]` Photos library from a not-sandboxed Phases (round A)" | First record of IDs saved |  |
| `[L-reopen-event]` | LEARNINGS.md:208 "Other investigations"<br>experiments/X-reopen-window.md:27 "`[X-reopen-window]` Launching Phases again while it runs" | A menu bar accessory gets the reopen call; the menu bar icon's view can open the window in every case |  |
| `[L-row-own-selection]` | LEARNINGS.md:142 "Sidebar rows"<br>experiments/X-active-badge-highlight.md:43 "`[X-active-badge-highlight]` The Active badge on the selection highlight" | Telling the row it's selected works, but the accent highlight also needs the sidebar to have focus |  |
| `[L-row-selection-focus]` | LEARNINGS.md:145 "Sidebar rows" (pointer)<br>experiments/X-active-badge-highlight.md:61 "`[X-active-badge-highlight]` The Active badge on the selection highlight" (pointer) | *Pointer:* Promoted to `[Q-tint-on-highlight]` (2026-11-06) |  |
| `[L-row-styles-on-highlight]` | LEARNINGS.md:138 "Sidebar rows"<br>experiments/X-active-badge-highlight.md:31 "`[X-active-badge-highlight]` The Active badge on the selection highlight" | On the selection highlight, hierarchical styles and the row's Label icon turn white; `.multicolor` and explicit colours don't adapt |  |
| `[L-sandbox-photos-works]` | LEARNINGS.md:343 "Photos library (issue #33)"<br>experiments/X-33-sandbox.md:80 "Round B: sandboxed (2026-11-12, macOS 27.2)" | The sandbox-only build reads Photos |  |
| `[L-sandbox-prefs-move]` | experiments/X-33-sandbox.md:52 "Round B: sandboxed (2026-11-12, macOS 27.2)"<br>LEARNINGS.md:335 "Photos library (issue #33)" (pointer) | The first sandboxed launch moved Phases' preferences into the container |  |
| `[L-sandbox-team-needed]` | experiments/X-33-sandbox.md:36 "Round B: sandboxed (2026-11-12, macOS 27.2)"<br>LEARNINGS.md:331 "Photos library (issue #33)" (pointer) | Bitrig won't build the Photos or the wallpaper-store entitlement without a development team |  |
| `[L-sandbox-x0-paths]` | experiments/X-33-sandbox.md:44 "Round B: sandboxed (2026-11-12, macOS 27.2)"<br>LEARNINGS.md:333 "Photos library (issue #33)" (pointer) | In the sandbox, `homeDirectoryForCurrentUser` and `NSHomeDirectory()` both point into the container | SourceLocation.swift, SystemWallpaperCheckTests.swift |
| `[L-sandbox-x1-no-entitlement]` | LEARNINGS.md:337 "Photos library (issue #33)"<br>experiments/X-33-sandbox.md:64 "Round B: sandboxed (2026-11-12, macOS 27.2)" | Without the Photos entitlement, the sandboxed build still got a Photos prompt |  |
| `[L-sandbox-x4-container-wallpaper]` | experiments/X-33-sandbox.md:91 "Round B: sandboxed (2026-11-12, macOS 27.2)"<br>LEARNINGS.md:348 "Photos library (issue #33)" (pointer) | A sandboxed Phases can set a file in its container as the wallpaper, and put back one outside it | SystemWallpaperCheckTests.swift |
| `[L-select-all-outside-window]` | LEARNINGS.md:481 "Test tools" | `selectAllSelectsBothSources` now fails: the driver refuses to click Select All, judging it outside the window, and sends no click |  |
| `[L-settings-panes]` | TEST-TOOLS.md:520 "Driving and measuring the Mac in tests" | Opening System Settings panes directly |  |
| `[L-settings-popup-look]` | LEARNINGS.md:186 "UI mockup (issues #2, #3, #26, #27)" (pointer) | *Pointer:* Promoted to `[Q-settings-popup-look]` (2026-11-26) |  |
| `[L-settings-thumbnail-placeholder]` | LEARNINGS.md:358 "Photos library (issue #33)" | System Settings › Wallpaper can show a "?" placeholder (dashed box) instead of the display's thumbnail while a Phases still from a folder… |  |
| `[L-space-leave-mid-fade]` | LEARNINGS.md:62 "Wallpaper, covers, and the menu bar"<br>experiments/X-persistent-cover.md:154 "`[X-persistent-cover]` Keeping a cover up between changes" | Leaving a Space mid-fade sends the change to the Space you arrive on |  |
| `[L-space-notify-after-swipe]` | ERRATA.md:90 "Wallpaper and menu bar (macOS)"<br>LEARNINGS.md:61 "Wallpaper, covers, and the menu bar" (pointer)<br>experiments/X-persistent-cover.md:153 "`[X-persistent-cover]` Keeping a cover up between changes" (pointer) | `activeSpaceDidChangeNotification` arrives after the swipe animation, about 0.9–1.1 s after ⌃←/⌃→, and until then `setDesktopImageURL` go… |  |
| `[L-stale-app-icon]` | LEARNINGS.md:224 "Other investigations" | After an app icon change, a rebuilt development build can show the old icon in the sidebar brand panel while About shows the new one |  |
| `[L-store-watch]` | LEARNINGS.md:201 "Other investigations"<br>experiments/X-wallpaper-store-watch.md:24 "`[X-wallpaper-store-watch]` Hearing outside wallpaper changes" | Watching the wallpaper store hears System Settings picks within about 0.3 s | OutsideChangeRule.swift, OutsideChangeRuleTests.swift, WallpaperStoreWatcher.swift |
| `[L-swipe-before-cover]` | LEARNINGS.md:74 "Wallpaper, covers, and the menu bar"<br>experiments/X-set-target-read.md:60 "`[X-set-target-read]` Which Space a set reaches during a swipe" | A swipe that starts before the cover appears takes the change with it to the new Space |  |
| `[L-swipe-set-race]` | ERRATA.md:110 "Wallpaper and menu bar (macOS)"<br>LEARNINGS.md:66 "Wallpaper, covers, and the menu bar" (pointer)<br>experiments/X-set-target-read.md:30 "`[X-set-target-read]` Which Space a set reaches during a swipe" (pointer) | A fade that ends during the swipe can still set the wallpaper on the arrival Space, even though the cover says its own Space is showing |  |
| `[L-swipe-set-read]` | LEARNINGS.md:67 "Wallpaper, covers, and the menu bar"<br>experiments/X-set-target-read.md:31 "`[X-set-target-read]` Which Space a set reaches during a swipe" | Reading the wallpaper just before a set doesn't predict which Space the set reaches |  |
| `[L-synthetic-clicks]` | TEST-TOOLS.md:531 "Driving and measuring the Mac in tests" | Synthetic input that works |  |
| `[L-test-window-height]` | TEST-TOOLS.md:492 "Driving and measuring the Mac in tests" | A borderless 240 pt harness window came out 241 pt tall on two displays |  |
| `[L-tint-on-highlight]` | LEARNINGS.md:136 "Sidebar rows" (pointer)<br>experiments/X-active-badge-highlight.md:29 "`[X-active-badge-highlight]` The Active badge on the selection highlight" (pointer) | *Pointer:* Promoted to `[Q-tint-on-highlight]` (2026-11-06) |  |
| `[L-toolbar-items-crash]` | LEARNINGS.md:180 "UI mockup (issues #2, #3, #26, #27)"<br>experiments/X-ui-mockup.md:33 "`[X-ui-mockup]` Interface mockup" | SwiftUI toolbar items crashed the window on open, likely colliding with `WindowLayoutConfigurator`'s own toolbar |  |
| `[L-twitch-measurement]` | TEST-TOOLS.md:506 "Driving and measuring the Mac in tests" | Measuring a twitch |  |
| `[L-twitch-returns]` | LEARNINGS.md:86 "Wallpaper, covers, and the menu bar"<br>experiments/X-cover-settle.md:31 "The twitch returns" | On macOS 27.2 (draft 22) the twitch came back because the 0.5 s settle removed the cover just before macOS's own motion; the fix was the … |  |
| `[L-ui-tests-sandboxed]` | LEARNINGS.md:416 "Test tools" (pointer) | *Pointer:* Promoted to TEST-TOOLS.md |  |
| `[L-window-size-ignored]` | LEARNINGS.md:456 "Test tools" | The harness's `windowSize` didn't size the window |  |

## Experiments `[X-…]`

| Tag | Where | Says | Cited in code |
|---|---|---|---|
| `[X-33-image-sources]` | experiments/X-33-image-sources.md:1 | Image sources: findings from merge 1 of issue #33 |  |
| `[X-33-photokit]` | experiments/X-33-photokit.md:1 | Photos library from a not-sandboxed Phases (round A) |  |
| `[X-33-photos-checks]` | experiments/X-33-photos-checks.md:1 | Merge #2 Photos checks |  |
| `[X-33-sandbox]` | experiments/X-33-sandbox.md:1 | Photos library from a sandboxed Phases (round B) |  |
| `[X-43-aerial-kind]` | experiments/X-43-aerial-kind.md:1 | Why did Quit restore a still over an Aerial? |  |
| `[X-active-badge-highlight]` | experiments/X-active-badge-highlight.md:1 | The Active badge on the selection highlight |  |
| `[X-click-state]` | experiments/X-click-state.md:1 | Do Phases' synthetic clicks need `mouseEventClickState`? |  |
| `[X-convert-xcode-project]` | experiments/X-convert-xcode-project.md:1 | What `bitrig convert-to-xcode-project` did to Phases |  |
| `[X-cover-settle]` | experiments/X-cover-settle.md:1 | Crossfade settle timing (drafts 5–32) |  |
| `[X-first-launch-activation]` | experiments/X-first-launch-activation.md:1 | First-launch window staying behind |  |
| `[X-hdr-wallpaper]` | experiments/X-hdr-wallpaper.md:1 | HDR photos as wallpaper |  |
| `[X-memory]` | experiments/X-memory.md:1 | Where Phases' memory goes |  |
| `[X-menubar-launcher-setting]` | experiments/X-menubar-launcher-setting.md:1 | Missing menu bar icon under Bitrig |  |
| `[X-menubar-overflow]` | experiments/X-menubar-overflow.md:1 | Menu bar overflow and the test harness |  |
| `[X-new-space-pauses]` | experiments/X-new-space-pauses.md:1 | A new Space read as an outside change |  |
| `[X-notice-click]` | experiments/X-notice-click.md:1 | What a click on the pause notification does |  |
| `[X-pause-banner-shift]` | experiments/X-pause-banner-shift.md:1 | Window content shifted up while paused |  |
| `[X-persistent-cover]` | experiments/X-persistent-cover.md:1 | Keeping a cover up between changes |  |
| `[X-reopen-window]` | experiments/X-reopen-window.md:1 | Launching Phases again while it runs |  |
| `[X-set-target-read]` | experiments/X-set-target-read.md:1 | Which Space a set reaches during a swipe |  |
| `[X-settings-popup-look]` | experiments/X-settings-popup-look.md:1 | Can the editor's pop-ups look like System Settings'? |  |
| `[X-stale-app-icon]` | experiments/X-stale-app-icon.md:1 | Old app icon in the brand panel after an icon change |  |
| `[X-ui-mockup]` | experiments/X-ui-mockup.md:1 | Interface mockup |  |
| `[X-ui-tests-sandboxed]` | experiments/X-ui-tests-sandboxed.md:1 | First fast-suite run since the sandbox |  |
| `[X-wallpaper-store-watch]` | experiments/X-wallpaper-store-watch.md:1 | Hearing outside wallpaper changes |  |

## Retired tags

No longer defined; mentioned as replaced or retired. The mention says what replaced each.

| Tag | Mentioned in |
|---|---|
| `[D-cover-settle]` | experiments/X-cover-settle.md:17, spec/transitions.md:323, spec/transitions.md:99 |
| `[D-quit-in-window]` | spec/interface.md:213 |
| `[D-relative-paths]` | spec/image-library.md:155 |
| `[D-settings-schedule-switch]` | spec/window.md:443 |
| `[D-sharing-no-interface]` | spec/displays.md:154, spec/window.md:468 |
