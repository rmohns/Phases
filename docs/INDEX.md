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
| `[D-cover-checks]` | TESTING.md:672 "Cover checks (draft 33)" | The persistent cover is checked by hand before it merges, and again after any change to `CrossfadeController` |  |
| `[D-cover-follows-displays]` | spec/transitions.md:281 "The persistent cover" | Covers follow display changes | CrossfadeController.swift, WallpaperScheduler.swift |
| `[D-cover-iosurface]` | spec/transitions.md:332 "A change, step by step" | Each cover holds one copy of its image, and only while it's up | CoverSurface.swift, CoverSurfaceTests.swift, CrossfadeController.swift |
| `[D-cover-level]` | spec/transitions.md:90 "The persistent cover" | It sits just above the desktop picture and below the desktop icons, so icons and windows don't flicker | CrossfadeController.swift |
| `[D-cover-only-for-crossfade]` | spec/transitions.md:244 "The persistent cover" | No cover at all unless crossfades will actually play | CrossfadeController.swift, WallpaperScheduler.swift |
| `[D-cover-opacity]` | spec/transitions.md:262 "The persistent cover" | The cover is 99% opaque, not 100% | CrossfadeController.swift |
| `[D-cover-pause-quit]` | spec/transitions.md:392 "A change, step by step" | Pause, Quit, and crashes | CrossfadeController.swift, WallpaperScheduler.swift |
| `[D-cover-per-space]` | spec/transitions.md:116 "The persistent cover" | Each Space keeps its own wallpaper | CrossfadeController.swift, WallpaperScheduler.swift |
| `[D-debug-test-folder]` | spec/sandbox.md:81 "Entitlements" | Debug builds can also read one test folder; Release builds, the ones that ship, can't | EntitlementsTests.swift, TestImages.swift |
| `[D-delete-selects-next]` | spec/window.md:165 "Phases window (one window for everything)" | After deleting a phase, the next phase down is selected | PhaseListSelection.swift, PhaseListSelectionTests.swift, PhaseListTests.swift, PhasesWindow.swift, UITestMode.swift |
| `[D-denied-means-off]` | spec/schedule.md:179 "Location" | Denied means no location at all, saved or fresh | LocationProvider.swift, PhaseAvailability.swift, PhaseAvailabilityTests.swift, WallpaperScheduler.swift |
| `[D-diagnostics-switch]` | TEST-TOOLS.md:148 "Diagnostics" | Diagnostic logging is built in and off by default | Diagnostics.swift, FocusHandoff.swift, PhasesWindow.swift, ReopenHandler.swift, WindowLayoutConfigurator.swift, WindowRequest.swift, WindowSpaceMover.swift |
| `[D-display-tab-shapes]` | spec/displays.md:61 "Per-display images" | A display's tab draws its outline at its real proportions | DisplayTabs.swift, PhaseEditorRulesTests.swift |
| `[D-display-tabs-visibility]` | spec/displays.md:73 "Per-display images" | The tab row shows when more than one display is connected | DisplayTabs.swift, PhaseEditorRulesTests.swift |
| `[D-display-tabs]` | spec/displays.md:21 "Per-display images" | The phase editor picks a display with a row of display tabs | DisplayTabs.swift, DisplayTabsRow.swift, PhaseEditor.swift, PhaseEditorRulesTests.swift, WallpaperScheduler.swift |
| `[D-display-uuid]` | spec/displays.md:108 "Display identity" | Displays are identified by their hardware UUID, so settings survive unplugging, reconnecting, and rearranging | DisplayIdentity.swift |
| `[D-doc-check]` | TESTING.md:219 "Rules" | A unit test checks the docs' tags and references, and keeps `docs/INDEX.md` current | DocIndex.swift |
| `[D-dock-while-open]` | spec/interface.md:94 "Dock icon and app menu" | Phases shows a Dock icon, and appears in the ⌘Tab switcher, only while its window is open | DockPresence.swift, OpenPhasesWindow.swift, PhasesApp.swift, WindowLayoutConfigurator.swift |
| `[D-duplicate-phase]` | spec/window.md:194 "Phases window (one window for everything)" | Duplicate makes a copy of a phase | Phase.swift, PhaseEditorRulesTests.swift, PhaseTests.swift, PhasesWindow.swift, WallpaperScheduler.swift |
| `[D-editor-checks]` | TESTING.md:982 "Phase editor checks (draft 63)" | The redesigned phase editor is checked by hand before it merges | PhaseEditorTests.swift |
| `[D-editor-labels]` | spec/phase-editor.md:43 "Phase editor" | Row labels are plain words with no trailing "…" | EditorRow.swift |
| `[D-editor-layout]` | spec/phase-editor.md:17 "Phase editor" | The phase editor is a name row, one block of settings, then the images | EditorBox.swift, EditorRow.swift, PhaseEditor.swift |
| `[D-editor-popups]` | spec/phase-editor.md:176 "Phase editor" | The settings block's pop-up menus look like System Settings' own | PhaseEditor.swift, SettingsPopUp.swift, StartsRow.swift |
| `[D-fade-in]` | spec/transitions.md:77 "Transitions" | fading the new image in over the old one | CrossfadeController.swift |
| `[D-fake-photos]` | TEST-TOOLS.md:241 "Launch arguments" | never touch the Photos library (draft 54) | FakePhotosProvider.swift, ImageLibrary.swift, ImageSourcesSection.swift, PhasesApp.swift, PhasesUITests.swift, PhotosProvider.swift, PhotosSourcesTests.swift, TestImages.swift, UITestMode.swift |
| `[D-first-launch-shows-window]` | spec/interface.md:169 "Dock icon and app menu" | The first launch opens the window | FirstLaunch.swift, FirstLaunchTests.swift, FirstLaunchWindow.swift, MenuBarLabel.swift, ReopenHandler.swift, UITestMode.swift, WallpaperScheduler.swift |
| `[D-follow-links]` | spec/image-library.md:101 "Image library" | Symlinks and Finder aliases count as what they point to | FolderScan.swift, FolderScanTests.swift, ImageLibrary.swift, LibraryListing.swift |
| `[D-footer-ax-labels]` | spec/window.md:186 "Phases window (one window for everything)" | + and − carry explicit accessibility labels | ImageSourcesSection.swift, PhasesWindow.swift |
| `[D-grid-collapse-saved]` | spec/image-library.md:284 "Image library" | The collapsed headings are saved | GridCollapseTests.swift, GridOutline.swift, GridOutlineTests.swift, ImageLibrary.swift |
| `[D-grid-collapse]` | spec/image-library.md:210 "Image library" | Every heading in the grid can collapse | GridCollapseTests.swift, GridOutline.swift, GridOutlineTests.swift, ImageGrid.swift, ImageGridNavigation.swift, ImageGridNavigationTests.swift, ImageLibrary.swift, ImageSourcesTests.swift, PhasesApp.swift, SyntheticInput.swift |
| `[D-grid-one-tab-stop]` | spec/image-library.md:291 "Image library" | Keyboard: the thumbnail grid is one Tab stop | FocusTests.swift, GridCollapseTests.swift, GridOutline.swift, GridOutlineTests.swift, ImageGrid.swift, ImageGridNavigation.swift, ImageGridNavigationTests.swift, ImageSourcesTests.swift, PhotosProvider.swift, PhotosSourcesTests.swift |
| `[D-grid-release-on-close]` | spec/image-library.md:336 "Image library" | Closing the Phases window releases the grid's thumbnails | FocusTests.swift, PhasesWindow.swift, WindowLayoutConfigurator.swift |
| `[D-hands-on-checks]` | TESTING.md:252 "Hands-on checks" | Every check that drives the mouse and keyboard or touches the real wallpaper is a hands-on check, and any one of them can run on its own | main.swift |
| `[D-image-header]` | spec/phase-editor.md:238 "Phase editor" | The image header pins to the top of the editor while the grid scrolls | ImageGrid.swift, ImageHeader.swift, PhaseEditor.swift, PhaseEditorTests.swift |
| `[D-image-sources]` | spec/image-library.md:13 "Image library" | The library is a list of image sources | FolderScan.swift, GridOutline.swift, ImageGrid.swift, ImageLibrary.swift, ImageSource.swift, ImageSourceTests.swift, ImageSourcesSection.swift, ImageSourcesTests.swift, LibraryListing.swift, ListFooter.swift, TestImages.swift, UITestMode.swift |
| `[D-in-order-remembers]` | spec/schedule.md:61 "Core model: phases plus rotation" | In order remembers the last image it showed and moves to the next one | AppliedState.swift, FetchAhead.swift, FetchAheadTests.swift, InOrderPicker.swift, InOrderPickerTests.swift, WallpaperCheck.swift, WallpaperScheduler.swift |
| `[D-initial-focus-sidebar]` | spec/window.md:234 "Phases window (one window for everything)" | The sidebar list has keyboard focus when the window opens | FocusTests.swift, PhasesApp.swift, PhasesWindow.swift |
| `[D-input-click-state]` | TEST-TOOLS.md:130 "Input driver" | Mouse down, up and drag carry click state 1, a single click, the way a mouse sends them | SyntheticInput.swift |
| `[D-input-driver]` | TEST-TOOLS.md:23 "Input driver" | All mouse and keyboard driving goes through `PhasesUIDriver`'s `SyntheticInput` | Package.swift, SyntheticInput.swift, main.swift |
| `[D-input-lands]` | TESTING.md:281 "Hands-on checks" | Prove the input landed before trusting a result | main.swift |
| `[D-input-modifier-keys]` | TEST-TOOLS.md:52 "Input driver" | A modifier is pressed as a key of its own, down before the key it modifies and up after it, the way a keyboard sends it | SyntheticInput.swift |
| `[D-keep-display-settings]` | spec/displays.md:126 "Display identity" | Saved display settings are never pruned | PhaseEditorRulesTests.swift, WallpaperScheduler.swift |
| `[D-links-outside-refused]` | spec/sandbox.md:155 "What changes inside the sandbox" | Links and aliases that point outside the source folder can't be read in the sandbox | FolderScan.swift, FolderScanTests.swift, ImageLibrary.swift |
| `[D-location-on-demand]` | spec/schedule.md:146 "Location" | Uses Location Services | PhaseAvailability.swift, WallpaperScheduler.swift |
| `[D-location-privacy-note]` | spec/schedule.md:151 "Location" | The Location section always carries a note | SettingsView.swift |
| `[D-login-consent]` | spec/launch-and-quit.md:12 "Launch at login: explicit consent only" |  | LaunchAtLogin.swift, SettingsView.swift |
| `[D-low-memory-note]` | spec/transitions.md:46 "Transitions" | On a Mac with less than 16 GB of memory, Settings suggests turning transitions off | LowMemoryNote.swift, LowMemoryNoteTests.swift, MemoryUse.swift, SettingsView.swift, UITestMode.swift |
| `[D-memory-flat]` | spec/project.md:126 "Memory" | Memory doesn't build up with wallpaper changes |  |
| `[D-memory-in-about]` | spec/window.md:460 "Pause banner and Settings" | Memory | LowMemoryNote.swift, LowMemoryNoteTests.swift, MemoryUse.swift, SettingsView.swift |
| `[D-memory-protocol]` | TESTING.md:764 "Memory checks (draft 32; covers, draft 33)" | Memory is checked by hand, ten changes per run, at least two runs before a change and two after |  |
| `[D-menu-no-shortcuts]` | spec/interface.md:83 "Menu bar menu" | The current image's filename is not shown in the menu | MenuContent.swift |
| `[D-menu-pause-verb]` | spec/interface.md:64 "Menu bar menu" | Pause Wallpaper Changes | MenuContent.swift, PauseBanner.swift, WallpaperScheduler.swift |
| `[D-menu-status-header]` | spec/interface.md:45 "Menu bar menu" | Kept short | MenuContent.swift |
| `[D-menubar-icon-paused]` | spec/interface.md:36 "Icons" | While paused, for any reason, the icon shows a small pause badge | MenuBarLabel.swift, PauseBannerTests.swift |
| `[D-menubar-icon]` | spec/interface.md:27 "Icons" | Menu bar icon | MenuBarLabel.swift |
| `[D-missed-latest-only]` | spec/schedule.md:130 "Missed changes: sleep, wake, unlock" |  | ScheduleEngineTests.swift, WallpaperCheck.swift, WallpaperCheckTests.swift |
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
| `[D-outside-change-check]` | TESTING.md:869 "Outside change check (draft 37)" | Pausing for a wallpaper picked elsewhere is checked by hand |  |
| `[D-outside-change-notice]` | spec/outside-change.md:63 "Wallpaper changed outside Phases" | Telling the user | MenuContent.swift, PauseNotifier.swift |
| `[D-outside-change-pauses]` | spec/outside-change.md:11 "Wallpaper changed outside Phases" | When someone picks a wallpaper in System Settings (or any other app), Phases pauses everything | CrossfadeController.swift, PauseReason.swift, RestorePoint.swift, WallpaperScheduler.swift |
| `[D-outside-change-rule]` | spec/outside-change.md:40 "Wallpaper changed outside Phases" | How a change is recognised | OutsideChangeRule.swift, OutsideChangeRuleTests.swift, WallpaperSetter.swift, WallpaperStoreWatcher.swift |
| `[D-own-images-no-fallback]` | spec/displays.md:102 "Per-display images" | If a display has its own selection but none of those images are available, that display keeps its current wallpaper; it does not fall bac… | WallpaperScheduler.swift |
| `[D-own-images-start-from-shared]` | spec/displays.md:92 "Per-display images" | Turning "Use different images on this display" on starts from a copy of the Shared selection | Phase.swift, PhaseEditorRulesTests.swift |
| `[D-pause-switch-disabled]` | spec/window.md:406 "Pause banner and Settings" | While the pause banner shows `[D-window-pause-banner]`, the switch is disabled | PauseBannerTests.swift, SettingsView.swift, WallpaperScheduler.swift |
| `[D-persistent-cover]` | spec/transitions.md:83 "The persistent cover" | After a crossfade, the cover stays up for as long as its Space is showing | CrossfadeController.swift |
| `[D-phase-actions]` | spec/window.md:207 "Phases window (one window for everything)" | Phase actions live in two places that list the same commands | PhasesWindow.swift |
| `[D-phase-cant-run]` | spec/schedule.md:188 "Location" | A phase that can't run is flagged in the sidebar | LocationProvider.swift, PhaseAvailability.swift, PhaseAvailabilityTests.swift, PhasesWindow.swift, WallpaperScheduler.swift |
| `[D-phase-status-inline]` | spec/phase-editor.md:218 "Phase editor" | Why a phase can't run shows under the row that fixes it | PhaseAvailability.swift, PhaseEditor.swift, PhaseEditorRulesTests.swift, StartReadout.swift |
| `[D-phase-turn-off]` | spec/schedule.md:217 "Location" | A phase can be turned off | Phase.swift, PhaseAvailability.swift, PhaseAvailabilityTests.swift, PhaseNameRow.swift, PhasesWindow.swift, WallpaperScheduler.swift |
| `[D-photos-cache]` | spec/photos.md:158 "Photos albums" | The photo cache | CrossfadeController.swift, ImageLibrary.swift, LibraryListing.swift, PhotoCache.swift, PhotoCacheRules.swift, PhotoCacheRulesTests.swift, WallpaperScheduler.swift, WallpaperStoreWatcher.swift |
| `[D-photos-changes]` | spec/photos.md:203 "Photos albums" | Album changes show up while Phases runs | ImageLibrary.swift, PhotoKitProvider.swift, PhotosProvider.swift, WallpaperScheduler.swift |
| `[D-photos-checks]` | TESTING.md:918 "Photos checks (draft 54)" | Real Photos behavior is checked by hand before merge #2 merges |  |
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
| `[D-row-status-not-cause]` | spec/schedule.md:200 "Location" | The row shows the status; the editor shows the cause | PhaseAvailability.swift, PhaseAvailabilityTests.swift, PhasesWindow.swift |
| `[D-sandbox-entitlements]` | spec/sandbox.md:44 "Entitlements" | Only these, each for something Phases does | EntitlementsTests.swift, ImageLibrary.swift, SystemWallpaperInspector.swift, WallpaperStoreWatcher.swift |
| `[D-sandbox-settings-move]` | spec/sandbox.md:180 "Settings when switching to the sandboxed build" | Existing settings carry over, by moving |  |
| `[D-sandboxed]` | spec/sandbox.md:12 "Sandbox" | Phases runs in the macOS App Sandbox | CrossfadeController.swift, FolderScan.swift, ImageLibrary.swift, WallpaperScheduler.swift |
| `[D-scan-each-folder-once]` | spec/image-library.md:133 "Image library" | Each folder is scanned at most once | FolderScan.swift, FolderScanTests.swift, ImageLibrary.swift |
| `[D-scoped-bookmarks]` | spec/image-library.md:177 "Image library" | Source bookmarks are security-scoped | ImageLibrary.swift, ImageSource.swift, WallpaperScheduler.swift |
| `[D-screen-change-no-reroll]` | spec/displays.md:175 "When displays change" | When macOS reports a display change (connect, disconnect, resolution, arrangement, or anything else that changes screen geometry), Phases… | ChangeRecord.swift, ChangeRecordTests.swift, WallpaperCheck.swift, WallpaperCheckTests.swift, WallpaperScheduler.swift |
| `[D-settings-at-top]` | spec/window.md:121 "Phases window (one window for everything)" | "App" section | PhasesWindow.swift |
| `[D-settings-order]` | spec/window.md:426 "Pause banner and Settings" | Settings selected | SettingsView.swift |
| `[D-settings-pause-switch]` | spec/window.md:400 "Pause banner and Settings" | Settings starts with a Pause wallpaper changes switch | SettingsView.swift, WallpaperScheduler.swift |
| `[D-sharing-per-phase]` | spec/displays.md:137 "Displays sharing the Shared images" | A setting of each phase | DisplayTabs.swift, ImageHeader.swift, Phase.swift, PhaseEditorRulesTests.swift, SettingsView.swift, WallpaperScheduler.swift |
| `[D-sidebar-always-visible]` | spec/window.md:329 "Phases window (one window for everything)" | The sidebar can't be hidden | PhasesCommands.swift, PhasesUITests.swift, PhasesWindow.swift, SidebarTests.swift, WindowLayoutConfigurator.swift |
| `[D-sidebar-footer-style]` | spec/window.md:176 "Phases window (one window for everything)" | + / − layout matches System Settings | ImageSourcesSection.swift, ImageSourcesTests.swift, ListFooter.swift, PhasesWindow.swift |
| `[D-sidebar-footer-view]` | spec/window.md:227 "Phases window (one window for everything)" | The + / − buttons are their own view, bound to the sidebar selection, not inline in the window's body | PhaseListTests.swift, PhasesWindow.swift |
| `[D-sidebar-limits-watch]` | spec/window.md:343 "Phases window (one window for everything)" | The limits are watched and put back whenever SwiftUI changes them | PhasesUITests.swift, SidebarTests.swift, WindowLayoutConfigurator.swift |
| `[D-sidebar-width]` | spec/window.md:243 "Phases window (one window for everything)" | Sidebar width | PhasesApp.swift, PhasesUITests.swift, PhasesWindow.swift, WindowLayoutConfigurator.swift |
| `[D-single-timer]` | spec/project.md:109 "Platform notes and limitations" | Scheduling uses a single timer aimed at the next event (a change, or from draft 54 a photo fetch ahead of one `[D-photos-fetch-ahead]`), … | WallpaperScheduler.swift |
| `[D-source-location]` | spec/image-library.md:166 "Image library" | Each source remembers where its folder is in two ways | ImageLibrary.swift, ImageSource.swift, ImageSourceTests.swift, SourceLocation.swift |
| `[D-source-names]` | spec/image-library.md:144 "Image library" | A saved image is named by its source and its path within that source | FolderScan.swift, ImageLibrary.swift, ImageSource.swift, ImageSourceTests.swift, ImageSourcesTests.swift, LibraryListing.swift |
| `[D-start-readout]` | spec/phase-editor.md:141 "Phase editor" | A dawn or dusk phase says when it starts today | PhaseEditor.swift, PhaseEditorRulesTests.swift, StartReadout.swift |
| `[D-starter-phases]` | spec/schedule.md:34 "Core model: phases plus rotation" | A new user starts with three phases | Phase.swift, PhaseTests.swift |
| `[D-starts-row]` | spec/phase-editor.md:105 "Phase editor" | The Starts row reads as a sentence, so its controls change with the trigger | OffsetParts.swift, Phase.swift, PhaseEditorRulesTests.swift, PhaseEditorTests.swift, StartReadout.swift, StartsRow.swift |
| `[D-store-unreadable-safe]` | spec/sandbox.md:118 "What changes inside the sandbox" | "Couldn't read the store" is never taken for "no Aerials" | RestorePoint.swift, SystemWallpaperCheck.swift, SystemWallpaperCheckTests.swift, SystemWallpaperInspector.swift, WallpaperStoreWatcher.swift |
| `[D-tall-toolbar]` | spec/window.md:295 "Phases window (one window for everything)" | Full-height toolbar over the detail pane only | App.swift, AppearanceTests.swift, PauseBannerTests.swift, WindowLayoutConfigurator.swift |
| `[D-test-memory-size]` | TEST-TOOLS.md:293 "Launch arguments" | act as if the Mac had `<n>` GB of memory, when launched with `-PhasesUITestMemoryGB <n>` as well (a whole number of GB, 1024³ bytes each) | LowMemoryNoteTests.swift, MemoryUse.swift, PhasesApp.swift, UITestMode.swift |
| `[D-test-no-location-prompt]` | TEST-TOOLS.md:214 "Launch arguments" | Test launches can skip the location prompt | LocationProvider.swift |
| `[D-test-outside-change-now]` | TEST-TOOLS.md:277 "Launch arguments" | pause as if the wallpaper had just been changed in System Settings, at any moment, when the test posts the distributed notification `Phas… | PauseBannerTests.swift, PhasesApp.swift, UITestMode.swift, WallpaperScheduler.swift |
| `[D-test-paused-by-outside-change]` | TEST-TOOLS.md:269 "Launch arguments" | start paused as if the wallpaper had just been changed in System Settings, when launched with `-PhasesUITestPausedByOutsideChange YES` as… | PhasesApp.swift, UITestMode.swift, WallpaperScheduler.swift |
| `[D-tests-carry-tags]` | TESTING.md:216 "Rules" | Tests for a tagged decision carry its tag |  |
| `[D-tests-unhosted]` | TESTING.md:205 "Rules" | The tests never launch Phases | GridOutline.swift, LowMemoryNote.swift, Package.swift, PauseReason.swift, ReduceMotionNote.swift, SystemWallpaperCheck.swift |
| `[D-ui-menubar-wide]` | TESTING.md:415 "How the tests work" | Phases' menu bar item is only clicked on a display at least 1200 points wide | PhasesApp.swift |
| `[D-ui-test-build-pick]` | TESTING.md:378 "How the tests work" | The UI tests launch the newest Bitrig Debug build, by the time in its folder's name, and refuse it unless its build number matches the pr… | BuildPick.swift, BuildPickTests.swift, PhasesApp.swift |
| `[D-ui-test-ids]` | TESTING.md:425 "How the tests work" | Controls the tests use carry accessibility identifiers | DisplayTabsRow.swift, GridCollapseTests.swift, ImageGrid.swift, ImageHeader.swift, ImageSourcesSection.swift, PauseBanner.swift, PhaseNameRow.swift, PhasesApp.swift, PhasesWindow.swift, SettingsView.swift |
| `[D-ui-test-mode]` | TEST-TOOLS.md:221 "Launch arguments" | Test mode: one launch that touches nothing real | FirstLaunch.swift, GridCollapseTests.swift, ImageLibrary.swift, LocationProvider.swift, PhaseListTests.swift, PhasesApp.swift, PhasesUITests.swift, PhotoCache.swift, RestorePoint.swift, SavedLayout.swift, SettingsStore.swift, TestImages.swift, UITestMode.swift, WallpaperScheduler.swift, WallpaperSetter.swift |
| `[D-ui-test-runner]` | TESTING.md:363 "How the tests work" | The UI tests drive Phases through the Accessibility API, not XCUITest | Package.swift, PhasesApp.swift, PhasesUITests.swift, SyntheticInput.swift |
| `[D-undo-remove-source]` | spec/image-library.md:77 "Image library" | Removing a source can be undone | ImageLibrary.swift, ImageSourcesSection.swift, ImageSourcesTests.swift |
| `[D-version-in-settings]` | spec/window.md:454 "Pause banner and Settings" | About section | AppVersion.swift, AppVersionTests.swift, SettingsView.swift |
| `[D-window-helper-order]` | spec/window.md:318 "Phases window (one window for everything)" | One AppKit helper, in a fixed order | PhasesWindow.swift, SidebarTests.swift, WindowLayoutConfigurator.swift |
| `[D-window-min-size]` | spec/window.md:258 "Phases window (one window for everything)" | Minimum window size | App.swift, EditorRow.swift, PauseBannerTests.swift, PhasesUITests.swift, PhasesWindow.swift |
| `[D-window-pause-banner]` | spec/window.md:358 "Pause banner and Settings" | While Phases has paused itself for an outside change `[D-outside-change-pauses]`, a pause banner sits at the top of the detail pane | PauseBanner.swift, PauseBannerTests.swift, PauseReason.swift, PauseReasonTests.swift, PhasesWindow.swift, SettingsView.swift, WallpaperScheduler.swift, WindowLayoutConfigurator.swift |
| `[D-window-title-phases]` | spec/window.md:298 "Phases window (one window for everything)" | The toolbar title is always **Phases**, the window's name; what's selected is named by the pane's own header: the phase editor's name row… | PhaseEditor.swift, SettingsView.swift |
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
| `[L-aerial-kind-lastuse]` | LEARNINGS.md:349 "Photos library (issue #33)" (pointer) | *Pointer:* Promoted to `[Q-store-kind-lastset]` (2026-11-27) |  |
| `[L-backdrop-private-store]` | EXPERIMENTS.md:244 "Notes outside any experiment"<br>LEARNINGS.md:76 "Wallpaper, covers, and the menu bar" | Backdrop (Cindori) puts video on the lock screen by registering entries in macOS's private wallpaper store |  |
| `[L-background-prominence-mac-list]` | EXPERIMENTS.md:543 "`[X-active-badge-highlight]` The Active badge on the selection highlight" (pointer)<br>LEARNINGS.md:136 "Sidebar rows" (pointer) | *Pointer:* Promoted to `[Q-tint-on-highlight]` (2026-11-06) |  |
| `[L-classic-mac-layout]` | EXPERIMENTS.md:870 "`[X-ui-mockup]` Interface mockup"<br>LEARNINGS.md:176 "UI mockup (issues #2, #3, #26, #27)" | Old-style Mac layouts were tried and dropped |  |
| `[L-click-state-not-needed]` | LEARNINGS.md:447 "Test tools" | Phases' clicks work with click state 0 on mouse up; the driver doesn't need to set it | SyntheticInput.swift |
| `[L-closed-menu-stale]` | EXPERIMENTS.md:1811 "`[X-33-image-sources]` Image sources: findings from merge 1 of issue #33"<br>LEARNINGS.md:393 "Image sources (issue #33, merge 1)" | A closed menu's items, read through AX, keep the title and enabled state from when the menu last opened |  |
| `[L-convert-xcode-project]` | LEARNINGS.md:231 "Other investigations" | `bitrig convert-to-xcode-project` carried every Project.json setting over, added two sandbox build settings, and lost team signing |  |
| `[L-cover-all-spaces]` | EXPERIMENTS.md:62 "`[X-persistent-cover]` Keeping a cover up between changes"<br>LEARNINGS.md:30 "Wallpaper, covers, and the menu bar" | A cover with `.canJoinAllSpaces` and `.stationary` shows on every Space and in Mission Control, and slides with each Space during a swipe… |  |
| `[L-cover-alpha-later]` | EXPERIMENTS.md:1490 "Still open"<br>LEARNINGS.md:401 "Open questions" | Could the 99% cover go to 100% once the menu bar has restyled, and does it matter? |  |
| `[L-cover-check-driving]` | TEST-TOOLS.md:539 "Driving and measuring the Mac in tests" | What the 2026-11-03 cover checks needed |  |
| `[L-cover-memory]` | EXPERIMENTS.md:96 "`[X-persistent-cover]` Keeping a cover up between changes"<br>LEARNINGS.md:46 "Wallpaper, covers, and the menu bar" | One full-screen cover image costs about 23 MB at 3024 × 1964, and the experiment held it about three times |  |
| `[L-cover-own-space]` | EXPERIMENTS.md:154 "`[X-persistent-cover]` Keeping a cover up between changes"<br>LEARNINGS.md:57 "Wallpaper, covers, and the menu bar" | A cover without `.canJoinAllSpaces` stays on its own Space, and can be removed when you leave it with nothing visible |  |
| `[L-cover-settle-delay]` | LEARNINGS.md:81 "Wallpaper, covers, and the menu bar" | Before draft 33, the cover came off 1.5 s after the set, clearing macOS's motion at 0.55–0.65 s; 0.5 s brought the twitch back |  |
| `[L-cover-three-displays]` | EXPERIMENTS.md:139 "`[X-persistent-cover]` Keeping a cover up between changes"<br>LEARNINGS.md:53 "Wallpaper, covers, and the menu bar" | The 99% cover held up on three displays |  |
| `[L-defaults-container-blocked]` | LEARNINGS.md:241 "Other investigations" | From Bitrig's shell, `defaults` can't read a sandboxed app's container: `defaults export` for the old ID wrote an empty plist (42 bytes, … |  |
| `[L-desktop-through-cover]` | EXPERIMENTS.md:82 "`[X-persistent-cover]` Keeping a cover up between changes"<br>LEARNINGS.md:40 "Wallpaper, covers, and the menu bar" | Desktop features work through a cover |  |
| `[L-detail-scroll-short]` | LEARNINGS.md:460 "Test tools" | In a 645 pt tall window, the detail pane hardly scrolls: the image grid's first row stays below the window's bottom edge |  |
| `[L-diagnostics-switch-saved]` | LEARNINGS.md:351 "Photos library (issue #33)" | Phases' saved `PhasesDiagnostics` switch can be on while `defaults` in Bitrig's shell says the domain doesn't exist |  |
| `[L-divider-drag-right]` | LEARNINGS.md:417 "Test tools" | In the first fast-suite run on the sandboxed build, dragging the sidebar divider far right left the sidebar at 239.5 pt, not 320 |  |
| `[L-first-launch-activation]` | EXPERIMENTS.md:1484 "`[X-first-launch-activation]` First-launch window staying behind"<br>LEARNINGS.md:229 "Other investigations" (pointer) | First-launch window staying behind: promoted to `[Q-launch-activate-refused]` (2026-11-06) |  |
| `[L-hdr-wallpaper]` | EXPERIMENTS.md:1361 "`[X-hdr-wallpaper]` HDR photos as wallpaper"<br>LEARNINGS.md:220 "Other investigations" | How does macOS draw an HDR photo (an iPhone HEIC with a gain map) as wallpaper: SDR, or with HDR headroom? | CoverSurface.swift |
| `[L-lockscreen-uses-real-wallpaper]` | EXPERIMENTS.md:71 "`[X-persistent-cover]` Keeping a cover up between changes"<br>LEARNINGS.md:34 "Wallpaper, covers, and the menu bar" | The lock screen and the login window show the real wallpaper of the Space you were on, not anything drawn by an app |  |
| `[L-login-dims-wallpaper]` | EXPERIMENTS.md:77 "`[X-persistent-cover]` Keeping a cover up between changes"<br>LEARNINGS.md:37 "Wallpaper, covers, and the menu bar" | At logout, macOS redraws the wallpaper for the login window, slightly darkened, with a visible twitch |  |
| `[L-main-memory]` | EXPERIMENTS.md:287 "`[X-memory]` Where Phases' memory goes"<br>LEARNINGS.md:95 "Memory" | The installed Release build of `main` measured 179 MB with its window closed |  |
| `[L-mem-ca-copy-test]` | ERRATA.md:247 "Wallpaper and menu bar (macOS)"<br>EXPERIMENTS.md:340 "`[X-memory]` Where Phases' memory goes" (pointer)<br>LEARNINGS.md:104 "Memory" (pointer) | Core Animation copied every CGImage we gave it, whatever its format; an IOSurface it used as is |  |
| `[L-mem-ca-copy]` | EXPERIMENTS.md:318 "`[X-memory]` Where Phases' memory goes"<br>LEARNINGS.md:102 "Memory" | Core Animation keeps its own full-screen copy of each cover image, and it outlives the window |  |
| `[L-mem-cover-windows-freed]` | EXPERIMENTS.md:313 "`[X-memory]` Where Phases' memory goes"<br>LEARNINGS.md:100 "Memory" | `main`'s cover windows are freed after each fade |  |
| `[L-mem-decode]` | EXPERIMENTS.md:394 "`[X-memory]` Where Phases' memory goes"<br>LEARNINGS.md:114 "Memory" | Each cover also decodes the file at full size first |  |
| `[L-mem-draft33-runs]` | EXPERIMENTS.md:493 "`[X-memory]` Where Phases' memory goes"<br>LEARNINGS.md:129 "Memory" | `[D-memory-protocol]` runs of draft 33 (persistent covers), 2026-11-03 |  |
| `[L-mem-fix-ideas]` | EXPERIMENTS.md:417 "`[X-memory]` Where Phases' memory goes"<br>LEARNINGS.md:123 "Memory" | Recommended fix, in order (agreed with the author 2026-10-30; untested in Phases) |  |
| `[L-mem-fix-runs]` | EXPERIMENTS.md:439 "`[X-memory]` Where Phases' memory goes"<br>LEARNINGS.md:126 "Memory" | `[D-memory-protocol]` runs of the fix, 2026-10-30 |  |
| `[L-mem-freed-held]` | EXPERIMENTS.md:386 "`[X-memory]` Where Phases' memory goes"<br>LEARNINGS.md:111 "Memory" | Freed full-screen buffers stay in the process for minutes |  |
| `[L-mem-iosurface-color]` | ERRATA.md:290 "Wallpaper and menu bar (macOS)"<br>EXPERIMENTS.md:341 "`[X-memory]` Where Phases' memory goes" (pointer)<br>LEARNINGS.md:105 "Memory" (pointer) | An IOSurface needs its color space attached, or colors come out wrong; attached, it matches the CGImage and still isn't copied |  |
| `[L-mem-no-upscale]` | EXPERIMENTS.md:381 "`[X-memory]` Where Phases' memory goes"<br>LEARNINGS.md:109 "Memory" | `loadImage` never scales an image up |  |
| `[L-mem-pressure-relief]` | EXPERIMENTS.md:342 "`[X-memory]` Where Phases' memory goes"<br>LEARNINGS.md:106 "Memory" | `malloc_zone_pressure_relief` didn't release the freed-but-held blocks |  |
| `[L-mem-reconcile]` | EXPERIMENTS.md:410 "`[X-memory]` Where Phases' memory goes"<br>LEARNINGS.md:121 "Memory" | This accounts for the earlier figures |  |
| `[L-mem-thumbnails]` | EXPERIMENTS.md:408 "`[X-memory]` Where Phases' memory goes"<br>LEARNINGS.md:119 "Memory" | Thumbnails are small |  |
| `[L-mem-timeline]` | EXPERIMENTS.md:304 "`[X-memory]` Where Phases' memory goes"<br>LEARNINGS.md:98 "Memory" | Footprint rises and falls with crossfades; it isn't a steady leak on `main` |  |
| `[L-mem-window]` | EXPERIMENTS.md:400 "`[X-memory]` Where Phases' memory goes"<br>LEARNINGS.md:116 "Memory" | Opening the window adds about 25 MB that stays after it closes |  |
| `[L-memory-tools]` | TEST-TOOLS.md:497 "Driving and measuring the Mac in tests" | Measuring memory |  |
| `[L-menu-label-dead-zones]` | LEARNINGS.md:187 "UI mockup (issues #2, #3, #26, #27)" | A SwiftUI `Menu` drawn as a custom pop-up (`.menuStyle(.button)`, `.buttonStyle(.plain)`, hover box drawn outside it) had dead zones and … |  |
| `[L-menubar-launcher-setting]` | EXPERIMENTS.md:1235 "`[X-menubar-launcher-setting]` Missing menu bar icon under Bitrig"<br>LEARNINGS.md:212 "Other investigations" | A Phases launched by Bitrig follows Bitrig's own switch in System Settings → Menu Bar |  |
| `[L-menubar-lazy-restyle]` | EXPERIMENTS.md:123 "`[X-persistent-cover]` Keeping a cover up between changes"<br>LEARNINGS.md:49 "Wallpaper, covers, and the menu bar" | macOS sometimes leaves menu bar text the wrong color for the wallpaper, with no cover involved, in either direction |  |
| `[L-menubar-overflow]` | EXPERIMENTS.md:1278 "`[X-menubar-overflow]` Menu bar overflow and the test harness"<br>LEARNINGS.md:216 "Other investigations" | Is Phases' menu bar icon hidden when the menu bar runs out of room? |  |
| `[L-misfire-not-seen]` | EXPERIMENTS.md:224 "`[X-set-target-read]` Which Space a set reaches during a swipe"<br>LEARNINGS.md:69 "Wallpaper, covers, and the menu bar" | With `[D-reset-on-quick-return]` in, the misfire didn't happen in 24 informative trials |  |
| `[L-mock-known-displays]` | EXPERIMENTS.md:893 "`[X-ui-mockup]` Interface mockup"<br>LEARNINGS.md:182 "UI mockup (issues #2, #3, #26, #27)" | The known-displays list grows without bound |  |
| `[L-motion-waits-for-reveal]` | EXPERIMENTS.md:51 "`[X-persistent-cover]` Keeping a cover up between changes"<br>LEARNINGS.md:26 "Wallpaper, covers, and the menu bar" | macOS seems to hold its wallpaper-change motion until the new wallpaper is first visible, not play it on a timer |  |
| `[L-nas-bookmark-rename]` | EXPERIMENTS.md:1801 "`[X-33-image-sources]` Image sources: findings from merge 1 of issue #33"<br>LEARNINGS.md:389 "Image sources (issue #33, merge 1)" | A security-scoped bookmark to a folder on a file server doesn't follow a rename; one to a local folder does |  |
| `[L-new-space-pauses]` | EXPERIMENTS.md:1035 "`[X-new-space-pauses]` A new Space read as an outside change"<br>LEARNINGS.md:203 "Other investigations" | Does a new Space read as an outside change? | OutsideChangeRuleTests.swift |
| `[L-no-fullscreen-apps]` | TEST-TOOLS.md:555 "Driving and measuring the Mac in tests" | Activity Monitor doesn't support full screen (it only zooms); use Calendar to test full screen |  |
| `[L-notice-click-launches-copy]` | EXPERIMENTS.md:774 "`[X-notice-click]` What a click on the pause notification does"<br>LEARNINGS.md:167 "Notification clicks" | A click on the pause notification can launch a second copy of Phases |  |
| `[L-nswindow-screen-rect]` | TEST-TOOLS.md:487 "Driving and measuring the Mac in tests" | `NSWindow(contentRect:…, screen:)` reads the rect relative to that screen, not in global coordinates |  |
| `[L-opaque-cover-freezes-menubar]` | ERRATA.md:66 "Wallpaper and menu bar (macOS)"<br>EXPERIMENTS.md:61 "`[X-persistent-cover]` Keeping a cover up between changes" (pointer)<br>LEARNINGS.md:29 "Wallpaper, covers, and the menu bar" (pointer) | A fully opaque full-screen cover stops the menu bar restyling for new wallpapers; a 99% opaque one doesn't |  |
| `[L-outside-change-hidden]` | EXPERIMENTS.md:92 "`[X-persistent-cover]` Keeping a cover up between changes"<br>LEARNINGS.md:43 "Wallpaper, covers, and the menu bar" | A wallpaper set by anything else while a cover is up is hidden by the cover |  |
| `[L-pause-banner-above-window]` | EXPERIMENTS.md:680 "`[X-pause-banner-shift]` Window content shifted up while paused"<br>LEARNINGS.md:158 "Pause banner" | With logging: the content sits above the window, the scroll positions are normal |  |
| `[L-pause-banner-inset]` | EXPERIMENTS.md:600 "`[X-pause-banner-shift]` Window content shifted up while paused"<br>LEARNINGS.md:148 "Pause banner" | A top `.safeAreaInset` banner broke the window two ways |  |
| `[L-pause-banner-rigid-split]` | EXPERIMENTS.md:701 "`[X-pause-banner-shift]` Window content shifted up while paused" (pointer)<br>LEARNINGS.md:161 "Pause banner" (pointer) | *Pointer:* Promoted to | PauseBannerTests.swift |
| `[L-pause-banner-runs]` | EXPERIMENTS.md:623 "`[X-pause-banner-shift]` Window content shifted up while paused"<br>LEARNINGS.md:151 "Pause banner" | UI test runs, 2026-11-07 21:48–21:54 |  |
| `[L-pause-banner-stack-still-shifts]` | EXPERIMENTS.md:657 "`[X-pause-banner-shift]` Window content shifted up while paused"<br>LEARNINGS.md:155 "Pause banner" | The stack fix didn't fix the shift | WindowLayoutConfigurator.swift |
| `[L-photos-album-order]` | EXPERIMENTS.md:1596 "`[X-33-photokit]` Photos library from a not-sandboxed Phases (round A)"<br>LEARNINGS.md:327 "Photos library (issue #33)" | The default fetch follows the album's own order | PhotoKitProvider.swift |
| `[L-photos-bitrig-vs-installed]` | LEARNINGS.md:249 "Other investigations" | Photos access can read "blocked" in the app while System Settings shows Phases allowed, when a Bitrig build runs alongside an installed c… |  |
| `[L-photos-deleted-album-race]` | EXPERIMENTS.md:1770 "`[X-33-photos-checks]` Merge #2 Photos checks"<br>LEARNINGS.md:382 "Photos library (issue #33)" | A photo from an album the author was deleting was set as the wallpaper at 22:18:02 |  |
| `[L-photos-formats-check]` | EXPERIMENTS.md:1762 "`[X-33-photos-checks]` Merge #2 Photos checks"<br>LEARNINGS.md:379 "Photos library (issue #33)" | An edited (cropped) photo, a Live Photo, an iPhone ProRAW+HEIC, and a Canon DSLR RAW all showed the way Photos shows them |  |
| `[L-photos-grant-needs-relaunch]` | EXPERIMENTS.md:1720 "`[X-33-photos-checks]` Merge #2 Photos checks"<br>LEARNINGS.md:367 "Photos library (issue #33)" | Turning Phases on under Privacy & Security › Photos didn't reach a running Phases |  |
| `[L-photos-grant-per-build]` | EXPERIMENTS.md:1732 "`[X-33-photos-checks]` Merge #2 Photos checks"<br>LEARNINGS.md:371 "Photos library (issue #33)" | Each Bitrig build loses the Photos grant |  |
| `[L-photos-ids-stable]` | EXPERIMENTS.md:1685 "Round B: sandboxed (2026-11-12, macOS 27.2)"<br>LEARNINGS.md:345 "Photos library (issue #33)" | Photo IDs held across builds and the sandbox |  |
| `[L-photos-new-build-asks]` | EXPERIMENTS.md:1670 "Round B: sandboxed (2026-11-12, macOS 27.2)"<br>LEARNINGS.md:339 "Photos library (issue #33)" | A new build asks for Photos again |  |
| `[L-photos-offline-check]` | EXPERIMENTS.md:1746 "`[X-33-photos-checks]` Merge #2 Photos checks"<br>LEARNINGS.md:375 "Photos library (issue #33)" | Offline, the fallback worked, but kept landing on the same photo |  |
| `[L-photos-x0-paths]` | EXPERIMENTS.md:1541 "`[X-33-photokit]` Photos library from a not-sandboxed Phases (round A)"<br>LEARNINGS.md:305 "Photos library (issue #33)" | Not sandboxed, every way of finding home agrees |  |
| `[L-photos-x1-permission]` | EXPERIMENTS.md:1545 "`[X-33-photokit]` Photos library from a not-sandboxed Phases (round A)"<br>LEARNINGS.md:309 "Photos library (issue #33)" | The Photos prompt worked from the probe launch |  |
| `[L-photos-x2-albums]` | EXPERIMENTS.md:1550 "`[X-33-photokit]` Photos library from a not-sandboxed Phases (round A)"<br>LEARNINGS.md:312 "Photos library (issue #33)" | PhotoKit lists the author's albums and folders of albums in sidebar order, nested |  |
| `[L-photos-x3-download]` | EXPERIMENTS.md:1560 "`[X-33-photokit]` Photos library from a not-sandboxed Phases (round A)"<br>LEARNINGS.md:316 "Photos library (issue #33)" | iCloud-only photos fail fast offline and download quickly online |  |
| `[L-photos-x4-cache-wallpaper]` | EXPERIMENTS.md:1579 "`[X-33-photokit]` Photos library from a not-sandboxed Phases (round A)"<br>LEARNINGS.md:319 "Photos library (issue #33)" | A file in `~/Library/Caches` works as a wallpaper |  |
| `[L-photos-x5-observer]` | EXPERIMENTS.md:1589 "`[X-33-photokit]` Photos library from a not-sandboxed Phases (round A)"<br>LEARNINGS.md:322 "Photos library (issue #33)" | The change observer fires while Phases is in the background | ImageLibrary.swift |
| `[L-photos-x6-ids]` | EXPERIMENTS.md:1593 "`[X-33-photokit]` Photos library from a not-sandboxed Phases (round A)"<br>LEARNINGS.md:324 "Photos library (issue #33)" | First record of IDs saved |  |
| `[L-reopen-event]` | EXPERIMENTS.md:1094 "`[X-reopen-window]` Launching Phases again while it runs"<br>LEARNINGS.md:207 "Other investigations" | What happens when Phases is launched again while it's running, and can the menu bar icon's view open the window? |  |
| `[L-row-own-selection]` | EXPERIMENTS.md:556 "`[X-active-badge-highlight]` The Active badge on the selection highlight"<br>LEARNINGS.md:141 "Sidebar rows" | Telling the row it's selected works, but the accent highlight also needs the sidebar to have focus |  |
| `[L-row-selection-focus]` | EXPERIMENTS.md:574 "`[X-active-badge-highlight]` The Active badge on the selection highlight" (pointer)<br>LEARNINGS.md:144 "Sidebar rows" (pointer) | *Pointer:* Promoted to `[Q-tint-on-highlight]` (2026-11-06) |  |
| `[L-row-styles-on-highlight]` | EXPERIMENTS.md:544 "`[X-active-badge-highlight]` The Active badge on the selection highlight"<br>LEARNINGS.md:137 "Sidebar rows" | What does adapt on the highlight |  |
| `[L-sandbox-photos-works]` | EXPERIMENTS.md:1677 "Round B: sandboxed (2026-11-12, macOS 27.2)"<br>LEARNINGS.md:342 "Photos library (issue #33)" | The sandbox-only build reads Photos |  |
| `[L-sandbox-prefs-move]` | EXPERIMENTS.md:1649 "Round B: sandboxed (2026-11-12, macOS 27.2)"<br>LEARNINGS.md:334 "Photos library (issue #33)" (pointer) | The first sandboxed launch moved Phases' preferences into the container |  |
| `[L-sandbox-team-needed]` | EXPERIMENTS.md:1633 "Round B: sandboxed (2026-11-12, macOS 27.2)"<br>LEARNINGS.md:330 "Photos library (issue #33)" (pointer) | Bitrig won't build the Photos or the wallpaper-store entitlement without a development team |  |
| `[L-sandbox-x0-paths]` | EXPERIMENTS.md:1641 "Round B: sandboxed (2026-11-12, macOS 27.2)"<br>LEARNINGS.md:332 "Photos library (issue #33)" (pointer) | In the sandbox, `homeDirectoryForCurrentUser` and `NSHomeDirectory()` both point into the container | SourceLocation.swift, SystemWallpaperCheckTests.swift |
| `[L-sandbox-x1-no-entitlement]` | EXPERIMENTS.md:1661 "Round B: sandboxed (2026-11-12, macOS 27.2)"<br>LEARNINGS.md:336 "Photos library (issue #33)" | Without the Photos entitlement, the sandboxed build still got a Photos prompt |  |
| `[L-sandbox-x4-container-wallpaper]` | EXPERIMENTS.md:1688 "Round B: sandboxed (2026-11-12, macOS 27.2)"<br>LEARNINGS.md:347 "Photos library (issue #33)" (pointer) | A sandboxed Phases can set a file in its container as the wallpaper, and put back one outside it | SystemWallpaperCheckTests.swift |
| `[L-select-all-outside-window]` | LEARNINGS.md:480 "Test tools" | `selectAllSelectsBothSources` now fails: the driver refuses to click Select All, judging it outside the window, and sends no click |  |
| `[L-settings-panes]` | TEST-TOOLS.md:520 "Driving and measuring the Mac in tests" | Opening System Settings panes directly |  |
| `[L-settings-popup-look]` | LEARNINGS.md:185 "UI mockup (issues #2, #3, #26, #27)" (pointer) | *Pointer:* Promoted to `[Q-settings-popup-look]` (2026-11-26) |  |
| `[L-settings-thumbnail-placeholder]` | LEARNINGS.md:357 "Photos library (issue #33)" | System Settings › Wallpaper can show a "?" placeholder (dashed box) instead of the display's thumbnail while a Phases still from a folder… |  |
| `[L-space-leave-mid-fade]` | EXPERIMENTS.md:170 "`[X-persistent-cover]` Keeping a cover up between changes"<br>LEARNINGS.md:61 "Wallpaper, covers, and the menu bar" | Leaving a Space mid-fade sends the change to the wrong Space |  |
| `[L-space-notify-after-swipe]` | ERRATA.md:90 "Wallpaper and menu bar (macOS)"<br>EXPERIMENTS.md:169 "`[X-persistent-cover]` Keeping a cover up between changes" (pointer)<br>LEARNINGS.md:60 "Wallpaper, covers, and the menu bar" (pointer) | `activeSpaceDidChangeNotification` arrives after the swipe animation, about 0.9–1.1 s after ⌃←/⌃→, and until then `setDesktopImageURL` go… |  |
| `[L-stale-app-icon]` | LEARNINGS.md:223 "Other investigations" | After an app icon change, a rebuilt development build can show the old icon in the sidebar brand panel while About shows the new one |  |
| `[L-store-watch]` | EXPERIMENTS.md:920 "`[X-wallpaper-store-watch]` Hearing outside wallpaper changes"<br>LEARNINGS.md:200 "Other investigations" | Can Phases hear a wallpaper change made in System Settings by watching macOS's wallpaper store? | OutsideChangeRule.swift, OutsideChangeRuleTests.swift, WallpaperStoreWatcher.swift |
| `[L-swipe-before-cover]` | EXPERIMENTS.md:232 "`[X-set-target-read]` Which Space a set reaches during a swipe"<br>LEARNINGS.md:73 "Wallpaper, covers, and the menu bar" | A swipe that starts before the cover appears takes the change with it |  |
| `[L-swipe-set-race]` | ERRATA.md:110 "Wallpaper and menu bar (macOS)"<br>EXPERIMENTS.md:202 "`[X-set-target-read]` Which Space a set reaches during a swipe" (pointer)<br>LEARNINGS.md:65 "Wallpaper, covers, and the menu bar" (pointer) | A fade that ends during the swipe can still set the wallpaper on the arrival Space, even though the cover says its own Space is showing |  |
| `[L-swipe-set-read]` | EXPERIMENTS.md:203 "`[X-set-target-read]` Which Space a set reaches during a swipe"<br>LEARNINGS.md:66 "Wallpaper, covers, and the menu bar" | Reading the wallpaper just before a set doesn't predict which Space the set reaches |  |
| `[L-synthetic-clicks]` | TEST-TOOLS.md:531 "Driving and measuring the Mac in tests" | Synthetic input that works |  |
| `[L-test-window-height]` | TEST-TOOLS.md:492 "Driving and measuring the Mac in tests" | A borderless 240 pt harness window came out 241 pt tall on two displays |  |
| `[L-tint-on-highlight]` | EXPERIMENTS.md:542 "`[X-active-badge-highlight]` The Active badge on the selection highlight" (pointer)<br>LEARNINGS.md:135 "Sidebar rows" (pointer) | *Pointer:* Promoted to `[Q-tint-on-highlight]` (2026-11-06) |  |
| `[L-toolbar-items-crash]` | EXPERIMENTS.md:880 "`[X-ui-mockup]` Interface mockup"<br>LEARNINGS.md:179 "UI mockup (issues #2, #3, #26, #27)" | SwiftUI toolbar items crashed the window on open |  |
| `[L-twitch-measurement]` | TEST-TOOLS.md:506 "Driving and measuring the Mac in tests" | Measuring a twitch |  |
| `[L-twitch-returns]` | EXPERIMENTS.md:2419 "The twitch returns"<br>LEARNINGS.md:85 "Wallpaper, covers, and the menu bar" | (demoted from ERRATA.md "Design history" on 2026-11-09; text unchanged below) |  |
| `[L-ui-tests-sandboxed]` | LEARNINGS.md:415 "Test tools" (pointer) | *Pointer:* Promoted to TEST-TOOLS.md |  |
| `[L-window-size-ignored]` | LEARNINGS.md:455 "Test tools" | The harness's `windowSize` didn't size the window |  |

## Experiments `[X-…]`

| Tag | Where | Says | Cited in code |
|---|---|---|---|
| `[X-33-image-sources]` | EXPERIMENTS.md:1787 | Image sources: findings from merge 1 of issue #33 |  |
| `[X-33-photokit]` | EXPERIMENTS.md:1511 | Photos library from a not-sandboxed Phases (round A) |  |
| `[X-33-photos-checks]` | EXPERIMENTS.md:1701 | Merge #2 Photos checks |  |
| `[X-33-sandbox]` | EXPERIMENTS.md:1603 | Photos library from a sandboxed Phases (round B) |  |
| `[X-43-aerial-kind]` | EXPERIMENTS.md:2254 | Why did Quit restore a still over an Aerial? |  |
| `[X-active-badge-highlight]` | EXPERIMENTS.md:528 | The Active badge on the selection highlight |  |
| `[X-click-state]` | EXPERIMENTS.md:2065 | Do Phases' synthetic clicks need `mouseEventClickState`? |  |
| `[X-convert-xcode-project]` | EXPERIMENTS.md:1835 | What `bitrig convert-to-xcode-project` did to Phases |  |
| `[X-cover-settle]` | EXPERIMENTS.md:2399 | Crossfade settle timing (drafts 5–32) |  |
| `[X-first-launch-activation]` | EXPERIMENTS.md:1473 | First-launch window staying behind |  |
| `[X-hdr-wallpaper]` | EXPERIMENTS.md:1350 | HDR photos as wallpaper |  |
| `[X-memory]` | EXPERIMENTS.md:266 | Where Phases' memory goes |  |
| `[X-menubar-launcher-setting]` | EXPERIMENTS.md:1225 | Missing menu bar icon under Bitrig |  |
| `[X-menubar-overflow]` | EXPERIMENTS.md:1264 | Menu bar overflow and the test harness |  |
| `[X-new-space-pauses]` | EXPERIMENTS.md:1024 | A new Space read as an outside change |  |
| `[X-notice-click]` | EXPERIMENTS.md:761 | What a click on the pause notification does |  |
| `[X-pause-banner-shift]` | EXPERIMENTS.md:583 | Window content shifted up while paused |  |
| `[X-persistent-cover]` | EXPERIMENTS.md:31 | Keeping a cover up between changes |  |
| `[X-reopen-window]` | EXPERIMENTS.md:1079 | Launching Phases again while it runs |  |
| `[X-set-target-read]` | EXPERIMENTS.md:187 | Which Space a set reaches during a swipe |  |
| `[X-settings-popup-look]` | EXPERIMENTS.md:2134 | Can the editor's pop-ups look like System Settings'? |  |
| `[X-stale-app-icon]` | EXPERIMENTS.md:1437 | Old app icon in the brand panel after an icon change |  |
| `[X-ui-mockup]` | EXPERIMENTS.md:859 | Interface mockup |  |
| `[X-ui-tests-sandboxed]` | EXPERIMENTS.md:1955 | First fast-suite run since the sandbox |  |
| `[X-wallpaper-store-watch]` | EXPERIMENTS.md:908 | Hearing outside wallpaper changes |  |

## Retired tags

No longer defined; mentioned as replaced or retired. The mention says what replaced each.

| Tag | Mentioned in |
|---|---|
| `[D-cover-settle]` | EXPERIMENTS.md:2405, spec/transitions.md:323, spec/transitions.md:99 |
| `[D-quit-in-window]` | spec/interface.md:213 |
| `[D-relative-paths]` | spec/image-library.md:155 |
| `[D-settings-schedule-switch]` | spec/window.md:421 |
| `[D-sharing-no-interface]` | spec/displays.md:154, spec/window.md:446 |
