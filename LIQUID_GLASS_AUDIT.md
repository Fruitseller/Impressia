# Liquid Glass Audit

Phase 1 discovery only. No source code was changed.

## 1. Deployment Target Check

Blocker: all app and package targets are below iOS 26.

| Target / module | Source | Deployment target | Status |
| --- | --- | ---: | --- |
| Impressia | `Impressia.xcodeproj/project.pbxproj` Debug/Release target configs | 17.0 | Blocker |
| ImpressiaShareExtension | `Impressia.xcodeproj/project.pbxproj` Debug/Release target configs | 17.0 | Blocker |
| ImpressiaWidgetExtension | `Impressia.xcodeproj/project.pbxproj` Debug/Release target configs | 17.0 | Blocker |
| Project-level default | `Impressia.xcodeproj/project.pbxproj` Debug/Release project configs | 17.0 | Blocker |
| PixelfedKit | `PixelfedKit/Package.swift` | iOS 17 | Blocker |
| ClientKit | `ClientKit/Package.swift` | iOS 17 | Blocker |
| EnvironmentKit | `EnvironmentKit/Package.swift` | iOS 17 | Blocker |
| ServicesKit | `ServicesKit/Package.swift` | iOS 17 | Blocker |
| WidgetsKit | `WidgetsKit/Package.swift` | iOS 17 | Blocker |

Notes:
- Liquid Glass APIs require a higher SDK/deployment posture than the current iOS 17 baseline.
- Widget migration is explicitly out of scope later, but the current project/package deployment settings still make iOS 26-only code unavailable unless raised or availability-gated.

## 2. Navigation Inventory

### NavigationStack / NavigationView / NavigationSplitView

| File:line | Pattern | Notes |
| --- | --- | --- |
| `Impressia/ImpressiaApp.swift:37` | `NavigationStack` | Root app container wrapping loading/sign-in/main flow. |
| `Impressia/Views/MainView.swift:115` | `NavigationStack(path:)` | Main authenticated navigation path. |
| `Impressia/Views/SettingsView/SettingsView.swift:27` | `NavigationStack` | Settings sheet route container. |
| `Impressia/Views/SettingsView/SettingsView.swift:28` | `NavigationView` | Nested inside `NavigationStack`; legacy/deprecated. |
| `Impressia/Views/ComposeView.swift:32` | `NavigationView` | Compose sheet; legacy/deprecated. |
| `Impressia/Views/ReportView.swift:42` | `NavigationView` | Report sheet; legacy/deprecated. |
| `ImpressiaShare/ComposeView.swift:26` | `NavigationView` | Share extension compose flow; legacy/deprecated. |
| `WidgetsKit/Sources/WidgetsKit/Views/PhotoEditorView.swift:24` | `NavigationView` | Photo editor sheet; legacy/deprecated. |
| `WidgetsKit/Sources/WidgetsKit/Views/PlaceSelectorView.swift:36` | `NavigationView` | Place selector sheet; legacy/deprecated. |

No `NavigationSplitView` occurrences found.

### TabView

| File:line | Pattern | Notes |
| --- | --- | --- |
| `Impressia/Widgets/ImageRowAsync.swift:88` | `TabView(selection:)` | Image carousel inside timeline content cell. Content, not navigation chrome. |
| `Impressia/Widgets/ImagesCarousel.swift:74` | `TabView(selection:)` | Image carousel in status detail content. Content, not navigation chrome. |
| `Impressia/Widgets/ImagesCarousel.swift:91` | `.tabViewStyle(PageTabViewStyle())` | Page carousel styling for content photos. |

### `.toolbar { ... }`

| File:line | Context | Notes |
| --- | --- | --- |
| `WidgetsKit/Sources/WidgetsKit/Views/PlaceSelectorView.swift:99` | Sheet navigation toolbar | Cancellation action. |
| `WidgetsKit/Sources/WidgetsKit/Views/BaseComposeView.swift:113` | Compose navigation toolbar | Publish and cancel actions; hosted by compose wrappers. |
| `WidgetsKit/Sources/WidgetsKit/Views/PhotoEditorView.swift:59` | Sheet navigation toolbar | Save and cancel actions. |
| `Impressia/Views/ReportView.swift:66` | Sheet navigation toolbar | Send and close actions. |
| `Impressia/Views/StatusesView.swift:70` | Screen toolbar | Hashtag follow action when applicable. |
| `Impressia/Views/MainView.swift:122` | Main toolbar | Leading avatar, principal menu, trailing compose when top menu position is active. |
| `Impressia/Views/EditProfileView.swift:73` | Screen toolbar | Save action. |
| `Impressia/Views/UserProfileView/UserProfileView.swift:41` | Screen toolbar | Account/profile menus. |
| `Impressia/Views/SettingsView/SettingsView.swift:64` | Settings toolbar | Close action. |

### `.sheet`, `.fullScreenCover`, `.popover`

| File:line | Pattern | Notes |
| --- | --- | --- |
| `Impressia/AppRouteur.swift:60` | `.sheet(item:)` | Central sheet router: compose, settings, report, share image. |
| `WidgetsKit/Sources/WidgetsKit/Views/BaseComposeView.swift:146` | `.sheet(item:)` | Photo details and place selector from compose. |
| `WidgetsKit/Sources/WidgetsKit/Views/BaseComposeView.swift:172` | `.fullScreenCover(isPresented:)` | Camera picker. |
| `Impressia/Views/StatusView/StatusView.swift:52` | `.fullScreenCover(item:)` | Full-screen image viewer. |
| `Impressia/ViewModifiers/NavigationMenuButtons.swift:97` | `.popoverTip` | TipKit popover attached to custom bottom navigation. |
| `Impressia/ViewModifiers/NavigationMenuButtons.swift:117` | `.popoverTip` | TipKit popover attached to custom bottom navigation. |
| `Impressia/Views/MainView.swift:208` | `.popoverTip` | TipKit popover attached to principal toolbar menu. |

### Custom Floating Controls / ZStack Overlays

| File:line | Pattern | Classification |
| --- | --- | --- |
| `Impressia/ViewModifiers/NavigationMenuButtons.swift:56` | `ZStack` overlaying bottom navigation over content | Navigation-layer floating controls. Strong Liquid Glass candidate. |
| `Impressia/ViewModifiers/NavigationMenuButtons.swift:88`, `:94`, `:103`, `:112` | `.background(.ultraThinMaterial)` on bottom menu groups / compose button | Current material-as-glass substitute on navigation chrome. |
| `Impressia/Views/HomeTimelineView.swift:58` | `ZStack` wrapping timeline and new-photos chip | Floating status/navigation affordance over photo feed. Candidate, but readability risk on noisy images. |
| `Impressia/Views/HomeTimelineView.swift:159` | `.background(.ultraThinMaterial)` on new-photos chip | Current material-as-glass substitute over photo feed. |
| `Impressia/Views/AccountAvatarMenu.swift:62` | `.background(.ultraThinMaterial)` on avatar button | Used by toolbar and floating bottom navigation. Candidate only in custom floating context; avoid double glass in system toolbar. |
| `WidgetsKit/Sources/WidgetsKit/Views/BaseComposeView.swift:101` | `ZStack(alignment: .bottom)` for keyboard/autocomplete bars | Floating over compose content while keyboard is visible. Navigation/utility layer. |
| `WidgetsKit/Sources/WidgetsKit/Views/BaseComposeView.swift:468` | `.background(.ultraThinMaterial)` on autocomplete bar | Current material-as-glass substitute. |
| `WidgetsKit/Sources/WidgetsKit/Views/BaseComposeView.swift:576` | `Color.keyboardToolbarColor` keyboard toolbar background | Custom bottom toolbar, but currently opaque/asset color rather than material. |
| `Impressia/AppRouteur.swift:77` | `.overlay` for success payment overlay | Modal overlay, not Liquid Glass migration target unless reviewed separately. |
| `WidgetsKit/Sources/WidgetsKit/Views/ImageUploadView.swift:125` | black rounded overlay on image upload warning/status | Content overlay on photo; not a navigation control. |
| `WidgetsKit/Sources/WidgetsKit/Widgets/ImageAlternativeText.swift:38` | black rounded overlay on media | Content/readability overlay; not a navigation control. |
| `WidgetsKit/Sources/WidgetsKit/Widgets/ImageAvatar.swift:42`, `:61` | black capsule badges on avatar image | Content/status badge, not navigation chrome. |
| `Impressia/Views/StatusView/StatusView.swift:184` | capsule background on reblog information | Content metadata chip; do not glass. |

## 3. Current Glass / Material Inventory

No `.glassEffect` or `GlassEffectContainer` occurrences found.

| File:line | Match | Context classification | Notes |
| --- | --- | --- | --- |
| `Impressia/ViewModifiers/NavigationMenuButtons.swift:88` | `.background(.ultraThinMaterial)` | Navigation | Bottom custom navigation capsule. Replace candidate. |
| `Impressia/ViewModifiers/NavigationMenuButtons.swift:94` | `.background(.ultraThinMaterial)` | Navigation | Bottom compose floating button. Replace candidate. |
| `Impressia/ViewModifiers/NavigationMenuButtons.swift:103` | `.background(.ultraThinMaterial)` | Navigation | Bottom compose floating button, alternate side. Replace candidate. |
| `Impressia/ViewModifiers/NavigationMenuButtons.swift:112` | `.background(.ultraThinMaterial)` | Navigation | Bottom custom navigation capsule, alternate side. Replace candidate. |
| `WidgetsKit/Sources/WidgetsKit/Views/BaseComposeView.swift:468` | `.background(.ultraThinMaterial)` | Navigation/utility | Autocomplete bar above keyboard. Candidate if targeting compose utility chrome. |
| `Impressia/Views/AccountAvatarMenu.swift:62` | `.background(.ultraThinMaterial)` | Mixed | Floating avatar button when used in custom bottom nav; system toolbar content when menu position is top. Needs context-aware handling to avoid double glass. |
| `Impressia/Views/HomeTimelineView.swift:159` | `.background(.ultraThinMaterial)` | Navigation/status affordance | Floating new-photos chip over photo feed. Candidate for `.glassEffect(.clear)` plus dimming/contrast review. |

No `.regularMaterial`, `.thinMaterial`, or `.thickMaterial` occurrences found.

## 4. Legacy Patterns

### `NavigationView`

| File:line | Notes |
| --- | --- |
| `ImpressiaShare/ComposeView.swift:26` | Share extension compose wrapper. |
| `WidgetsKit/Sources/WidgetsKit/Views/PlaceSelectorView.swift:36` | Sheet view used by compose. |
| `WidgetsKit/Sources/WidgetsKit/Views/PhotoEditorView.swift:24` | Sheet view used by compose/photo routes. |
| `Impressia/Views/ReportView.swift:42` | Report sheet. |
| `Impressia/Views/ComposeView.swift:32` | Main app compose sheet. |
| `Impressia/Views/SettingsView/SettingsView.swift:28` | Nested in `NavigationStack`; likely removable/replacable. |

### `.foregroundColor` candidates

There are 96 `.foregroundColor` matches across app, widget extension, and WidgetsKit. Migration to `.foregroundStyle` should be P3 polish, not mixed into Liquid Glass behavior changes unless touching the same lines.

Highest-concentration files:

| Count | File |
| ---: | --- |
| 8 | `Impressia/Views/SettingsView/Subviews/MediaSettingsView.swift` |
| 7 | `WidgetsKit/Sources/WidgetsKit/Views/BaseComposeView.swift` |
| 5 | `Impressia/Views/UserProfileView/Subviews/UserProfileHeaderView.swift` |
| 5 | `Impressia/Views/EditProfileView.swift` |
| 4 | `WidgetsKit/Sources/WidgetsKit/Widgets/TagWidget.swift` |
| 4 | `Impressia/Views/StatusView/StatusView.swift` |
| 4 | `Impressia/Views/NotificationsView/Subviews/NotificationRowView.swift` |
| 3 | `Impressia/ViewModifiers/NavigationMenuButtons.swift` |
| 3 | `Impressia/Views/HomeTimelineView.swift` |
| 3 | `Impressia/Views/InstanceView.swift` |
| 3 | `WidgetsKit/Sources/WidgetsKit/Views/PlaceSelectorView.swift` |

Navigation-adjacent `.foregroundColor` examples:
- `Impressia/ViewModifiers/NavigationMenuButtons.swift:130`, `:152`, `:165`
- `Impressia/Views/MainView.swift:207`, `:233`
- `Impressia/Views/HomeTimelineView.swift:158`
- `Impressia/Views/ReportView.swift:53`
- `WidgetsKit/Sources/WidgetsKit/Views/BaseComposeView.swift:459`, `:570`
- `WidgetsKit/Sources/WidgetsKit/Views/PlaceSelectorView.swift:80`, `:83`, `:89`

### `ObservableObject` / `@StateObject` / `@ObservedObject`

| File:line | Pattern | Notes |
| --- | --- | --- |
| `Impressia/Services/AuthorizationSession.swift:10` | `ObservableObject` | NSObject + `ASWebAuthenticationPresentationContextProviding`; not a Liquid Glass concern. |

No `@StateObject` or `@ObservedObject` occurrences found.

## 5. Asset / Custom Icon / Filled Button Check

### Custom tab/navigation icons

| Location | Notes |
| --- | --- |
| `Impressia/Assets.xcassets/SF Symbols/custom.rocket.symbolset` | Custom symbol used for reboost actions/options. |
| `Impressia/Assets.xcassets/SF Symbols/custom.rocket.fill.symbolset` | Filled custom symbol used for reboost/favourite-like states. |
| `Assets/SF Symbols/*.afdesign` | Source design files for custom rocket variants. |
| `Impressia/Views/MainView.swift:73` | Main navigation icons use SF Symbols only; no custom filled backgrounds. |
| `Impressia/Widgets/MainNavigationOptions.swift` | Menu list of the same navigation modes; SF Symbols/custom rocket only. |

### Custom toolbar/floating buttons with filled backgrounds

| File:line | Element | Collision risk |
| --- | --- | --- |
| `Impressia/ViewModifiers/NavigationMenuButtons.swift:88`, `:94`, `:103`, `:112` | Custom bottom navigation background uses `.ultraThinMaterial` + capsule/circle clipping | High relevance; should become sparse Liquid Glass controls after deployment blocker is solved. |
| `Impressia/Views/AccountAvatarMenu.swift:62` | Avatar button background uses `.ultraThinMaterial` | Medium risk; shared component is used in both system toolbar and floating custom nav. Needs context-aware API or wrapper. |
| `Impressia/Views/HomeTimelineView.swift:159` | New-photos chip uses `.ultraThinMaterial` + capsule | High relevance; floating over noisy photo feed, needs contrast/dimming review. |
| `WidgetsKit/Sources/WidgetsKit/Views/BaseComposeView.swift:468` | Autocomplete bar uses `.ultraThinMaterial` | Medium relevance; utility chrome above keyboard, not content. |
| `WidgetsKit/Sources/WidgetsKit/Views/BaseComposeView.swift:576` | Keyboard toolbar uses `Color.keyboardToolbarColor` | Medium relevance; custom bottom toolbar. Could stay opaque for accessibility unless plan says otherwise. |
| `WidgetsKit/Sources/WidgetsKit/Views/ImageUploadView.swift:125` | Black rounded label over image | Content/readability overlay; should not become glass. |
| `WidgetsKit/Sources/WidgetsKit/Widgets/ImageAlternativeText.swift:38` | Black rounded label over image | Content/readability overlay; should not become glass. |
| `WidgetsKit/Sources/WidgetsKit/Widgets/TagWidget.swift:43` | Colored capsule tag | Content/status chip; should not become glass. |
| `Impressia/Views/StatusView/StatusView.swift:184` | Reblog information capsule | Content metadata chip; should not become glass. |

### App icons / branding assets

Many app icon variants exist under `Impressia/Assets.xcassets/AppIcons`. These are app icon assets, not tab bar/toolbar controls, and do not directly collide with Liquid Glass navigation controls.

## Phase 2 Inputs

Likely P0 candidates:
- Raise deployment targets for native app/share/widget targets and local Swift packages, or decide on availability-gated Liquid Glass support.
- Replace legacy `NavigationView` in main app and shared compose-related sheets with `NavigationStack`.
- Remove nested `NavigationStack` + `NavigationView` in settings.

Likely P1/P2 candidates:
- Replace `.ultraThinMaterial` in `NavigationMenuButtons` with properly grouped Liquid Glass floating controls.
- Handle `AccountAvatarMenu` carefully because the same component appears inside both system toolbar and custom floating bottom navigation.
- Replace or remove `.ultraThinMaterial` on `HomeTimelineView` new-photos chip; prefer a conservative `.glassEffect(.clear)` plan plus dimming/contrast checks because it floats over photos.
- Review `BaseComposeView` autocomplete/keyboard toolbar as utility chrome; do not touch content image overlays.

Out-of-scope findings for later follow-up:
- Broad `.foregroundColor` to `.foregroundStyle` migration is sizeable and should be P3 or separate.
- Widget visual migration should stay separate as requested, despite deployment settings being part of the same project/package baseline.
