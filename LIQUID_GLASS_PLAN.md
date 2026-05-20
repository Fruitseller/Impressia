# Liquid Glass Migration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate Impressia's navigation-layer controls to iOS 26.5 Liquid Glass, with no support for iOS versions below 26.

**Architecture:** Raise the whole app/package baseline first, then migrate only navigation and floating utility chrome. System-provided NavigationStack, TabView, and sheet chrome should not receive explicit glass; custom floating controls get explicit Liquid Glass only where they sit above content.

**Tech Stack:** SwiftUI, Xcode project build settings, Swift Package Manager package manifests, iOS 26.5 SDK, Liquid Glass APIs.

---

## Scope Rules

- No code changes happen until Phase 3 is explicitly approved.
- Phase 3 must run one P-stage at a time, with a pause after each stage.
- After every code/project change in Phase 3, run:

```bash
xcodebuild -project Impressia.xcodeproj -scheme Impressia -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

- Widgets are not visually migrated in this pass, but package/target deployment settings must still be raised if required to compile shared iOS 26.5 code.
- No PixelfedKit/ClientKit API changes, CoreData migrations, translations, or unrelated refactors.

## Files Expected To Change

| File | Responsibility in migration |
| --- | --- |
| `Impressia.xcodeproj/project.pbxproj` | Raise project, app, share extension, and widget extension deployment targets to iOS 26.5. |
| `PixelfedKit/Package.swift` | Raise package platform to `.iOS(.v26)` or the closest SwiftPM spelling available for iOS 26. |
| `ClientKit/Package.swift` | Same package platform raise. |
| `EnvironmentKit/Package.swift` | Same package platform raise. |
| `ServicesKit/Package.swift` | Same package platform raise. |
| `WidgetsKit/Package.swift` | Same package platform raise because compose/shared UI will compile with the app. |
| `Impressia/Views/SettingsView/SettingsView.swift` | Remove legacy nested `NavigationView`; keep one `NavigationStack`. |
| `Impressia/Views/ComposeView.swift` | Replace `NavigationView` with `NavigationStack`. |
| `ImpressiaShare/ComposeView.swift` | Replace `NavigationView` with `NavigationStack`. |
| `Impressia/Views/ReportView.swift` | Replace `NavigationView` with `NavigationStack`. |
| `WidgetsKit/Sources/WidgetsKit/Views/PhotoEditorView.swift` | Replace `NavigationView` with `NavigationStack`. |
| `WidgetsKit/Sources/WidgetsKit/Views/PlaceSelectorView.swift` | Replace `NavigationView` with `NavigationStack`. |
| `Impressia/ViewModifiers/NavigationMenuButtons.swift` | Convert bottom floating navigation material capsules/buttons to explicit Liquid Glass; likely add `GlassEffectContainer`. |
| `Impressia/Views/AccountAvatarMenu.swift` | Make avatar background context-aware so custom floating nav can use glass without double-applying glass in system toolbar. |
| `Impressia/Views/HomeTimelineView.swift` | Replace the new-photos material chip with a conservative Liquid Glass floating chip and readability treatment. |
| `WidgetsKit/Sources/WidgetsKit/Views/BaseComposeView.swift` | Review compose autocomplete/keyboard utility chrome; migrate only if it is clearly navigation/utility chrome and not content. |
| `FOLLOWUPS.md` | Record out-of-scope findings if discovered during implementation. |

## P0 - Blocker Entfernen

### P0.1 Raise native deployment targets to iOS 26.5

**File/line:** `Impressia.xcodeproj/project.pbxproj`, existing `IPHONEOS_DEPLOYMENT_TARGET = 17.0;` entries around lines 1208, 1243, 1277, 1310, 1383, 1441, 1478, 1522.

**Planned change:** Set every native project/target `IPHONEOS_DEPLOYMENT_TARGET` to `26.5`.

**Reason:** You clarified that iOS < 26 does not need support. Liquid Glass can be adopted directly instead of availability-gating.

**Risk:** Medium. Requires an Xcode/iOS 26.5 SDK environment and may expose SDK-driven compile issues.

**Implementation checkpoint:**
- [ ] Change only deployment target values in the pbxproj.
- [ ] Show diff for the pbxproj.
- [ ] Build Impressia with iPhone 16 Pro destination.

### P0.2 Raise local Swift package platforms

**File/line:** `PixelfedKit/Package.swift:10`, `ClientKit/Package.swift:10`, `EnvironmentKit/Package.swift:10`, `ServicesKit/Package.swift:10`, `WidgetsKit/Package.swift:10`.

**Planned change:** Replace `.iOS(.v17)` with the supported SwiftPM platform spelling for iOS 26. If SwiftPM in the installed toolchain does not expose `.v26`, use the exact syntax accepted by the active Xcode toolchain and document it in the diff rationale.

**Reason:** Shared code cannot freely reference iOS 26 APIs while package manifests still declare iOS 17.

**Risk:** Medium. The exact SwiftPM enum case depends on the installed Xcode/toolchain.

**Implementation checkpoint:**
- [ ] Probe accepted SwiftPM iOS 26 platform spelling if needed.
- [ ] Update package manifests only.
- [ ] Show diff per package group.
- [ ] Build Impressia.

### P0.3 Replace legacy `NavigationView`

**Files/lines:**
- `Impressia/Views/SettingsView/SettingsView.swift:27-84`
- `Impressia/Views/ComposeView.swift:32`
- `ImpressiaShare/ComposeView.swift:26`
- `Impressia/Views/ReportView.swift:42`
- `WidgetsKit/Sources/WidgetsKit/Views/PhotoEditorView.swift:24`
- `WidgetsKit/Sources/WidgetsKit/Views/PlaceSelectorView.swift:36`

**Planned change:** Replace `NavigationView` with `NavigationStack`. In settings, remove the nested `NavigationView` and keep a single `NavigationStack` around the `List` plus routing modifiers.

**Reason:** `NavigationView` is legacy/deprecated and is a blocker for a clean iOS 26 navigation surface.

**Risk:** Medium for settings because nested navigation is currently doing route/sheet containment. Low for simple sheet wrappers.

**Implementation checkpoint:**
- [ ] Change one file at a time.
- [ ] Show before/after diff and 1-2 sentence rationale per file.
- [ ] Build after each file.

## P1 - Glass-Misuse Fixen

### P1.1 Remove material-as-glass from floating bottom navigation

**File/line:** `Impressia/ViewModifiers/NavigationMenuButtons.swift:88`, `:94`, `:103`, `:112`.

**Planned change:** Replace `.background(.ultraThinMaterial)` usage with explicit Liquid Glass applied as the last visual modifier on the floating capsule/circle controls. Use `GlassEffectContainer` around the nearby bottom controls because there are 2+ glass elements in a compact bar.

**Reason:** These are custom navigation-layer controls floating above content, which is the right place for sparse Liquid Glass. Current `.ultraThinMaterial` is a pre-iOS-26 glass substitute.

**Risk:** Medium. Modifier order matters, and the current `clipShape`/padding chain may need reshaping so `.glassEffect()` is last.

### P1.2 Make `AccountAvatarMenu` safe across toolbar and floating-nav contexts

**File/line:** `Impressia/Views/AccountAvatarMenu.swift:49-63`; usage in `Impressia/Views/MainView.swift:218-220` and `Impressia/ViewModifiers/NavigationMenuButtons.swift:80`, `:115`.

**Planned change:** Add a narrow parameter or wrapper behavior so the avatar can avoid explicit glass inside system toolbar but participate in glass when used in custom bottom navigation.

**Reason:** The same component is used both as a system toolbar item and as a custom floating control. Applying glass unconditionally would double-apply glass in system chrome.

**Risk:** Medium. Touches a shared navigation component and must preserve account menu behavior.

### P1.3 Replace timeline new-photos material chip conservatively

**File/line:** `Impressia/Views/HomeTimelineView.swift:138-160`.

**Planned change:** Replace `.background(.ultraThinMaterial)` with a Liquid Glass treatment appropriate for a floating chip over photo content. Prefer `.glassEffect(.clear)` plus a subtle dim/contrast layer if readability needs it.

**Reason:** This chip floats over a very noisy photo feed. It is navigation/status chrome, but readability matters more than decorative glass.

**Risk:** Medium. Visual quality depends on busy image backgrounds, Reduce Transparency, and contrast settings.

### P1.4 Keep content overlays opaque

**Files/lines:**
- `WidgetsKit/Sources/WidgetsKit/Views/ImageUploadView.swift:125`
- `WidgetsKit/Sources/WidgetsKit/Widgets/ImageAlternativeText.swift:38`
- `WidgetsKit/Sources/WidgetsKit/Widgets/ImageAvatar.swift:42`, `:61`
- `Impressia/Views/StatusView/StatusView.swift:184`

**Planned change:** No code change unless implementation accidentally affects these areas. Record in `FOLLOWUPS.md` only if visual issues are found.

**Reason:** These are content/readability overlays or metadata chips, not navigation controls. The "no glass on content cells/images/list rows" rule applies.

**Risk:** Low.

## P2 - Floating Controls Als Glass Markieren

### P2.1 Finalize bottom navigation grouping

**File/line:** `Impressia/ViewModifiers/NavigationMenuButtons.swift:76-118`.

**Planned change:** Group bottom menu capsule, compose button, and avatar button inside one `GlassEffectContainer` where spatially adjacent. Use `.glassEffect(.regular.interactive())` for tappable primary floating controls where the API supports it.

**Reason:** Multiple nearby interactive glass controls should be in a glass container so the system can render them coherently.

**Risk:** Medium. Needs visual verification in both `bottomRight` and alternate bottom menu positions.

### P2.2 Compose keyboard/autocomplete utility chrome review

**File/line:** `WidgetsKit/Sources/WidgetsKit/Views/BaseComposeView.swift:450-576`.

**Planned change:** Migrate the autocomplete strip at `:468` only if it remains a floating utility layer after P0/P1. Keep `keyboardToolbarColor` if opaque contrast is better for accessibility, or use a single grouped glass treatment for both autocomplete and keyboard toolbar if visual review shows it is appropriate.

**Reason:** Compose controls are utility chrome, but they sit near text input and keyboard where clarity can outweigh glass.

**Risk:** High for usability if contrast or keyboard ergonomics regress.

### P2.3 Status detail image actions audit

**File/line:** `Impressia/Views/StatusView/StatusView.swift:159-163`, `Impressia/Widgets/InteractionRow.swift`.

**Planned change:** Do not move `InteractionRow` in this migration unless explicitly approved. If a future floating action bar is desired for status detail, record it in `FOLLOWUPS.md`.

**Reason:** The current actions are inline content controls, not floating buttons. Turning them into FABs would be a larger UX change.

**Risk:** Low if no change; high if converted without design approval.

## P3 - Polish

### P3.1 Migrate touched navigation-adjacent `.foregroundColor` to `.foregroundStyle`

**Files/lines likely touched:**
- `Impressia/ViewModifiers/NavigationMenuButtons.swift:130`, `:152`, `:165`
- `Impressia/Views/MainView.swift:207`, `:233`
- `Impressia/Views/HomeTimelineView.swift:158`
- `WidgetsKit/Sources/WidgetsKit/Views/BaseComposeView.swift:459`, `:570`

**Planned change:** Convert only lines already touched by P1/P2 to `.foregroundStyle`.

**Reason:** Broad `.foregroundColor` migration is not required for Liquid Glass and would be noisy. Touched navigation chrome can be modernized locally.

**Risk:** Low.

### P3.2 Avoid broad style cleanup

**File/line:** All other `.foregroundColor` matches.

**Planned change:** No broad sweep. Add a follow-up note if needed.

**Reason:** There are 96 matches across app, WidgetsKit, and widget views. A mass edit would violate the scope and dry-run constraints.

**Risk:** Low.

### P3.3 Accessibility and visual checklist

**Files:** Every view touched in P1/P2.

**Planned change:** Generate manual review instructions after implementation:
- Light Mode and Dark Mode.
- Reduce Transparency on/off.
- Increase Contrast on/off.
- Dynamic Type Large.
- Busy photo timeline backgrounds, especially `HomeTimelineView`.
- Bottom menu position top, bottom-right, and alternate bottom layout.

**Reason:** Liquid Glass is visual and environmental; build success alone is insufficient.

**Risk:** Low.

## Out Of Scope

- PixelfedKit and ClientKit API behavior.
- CoreData/SwiftData schema or migration work.
- String catalog or translation edits.
- Widget visual Liquid Glass migration. Deployment settings may change, but widget UI polish is a separate phase.
- Reworking timeline cells, image containers, post cards, list rows, or inline status metadata into glass.
- Replacing app icons, branding assets, or custom rocket symbols.
- Broad `.foregroundColor` migration outside touched navigation chrome.
- Creating new ViewModels or changing the app's singleton/environment architecture.

## Phase 3 Execution Order

### Task 1: P0 deployment target raise

- [ ] Modify `Impressia.xcodeproj/project.pbxproj`.
- [ ] Modify five `Package.swift` files.
- [ ] Show diffs.
- [ ] Build `Impressia`.
- [ ] Pause for review.

### Task 2: P0 navigation modernization

- [ ] Replace `NavigationView` in one file.
- [ ] Show diff and rationale.
- [ ] Build.
- [ ] Repeat for the remaining listed files.
- [ ] Pause for review.

### Task 3: P1 material misuse cleanup

- [ ] Update `NavigationMenuButtons` first.
- [ ] Build and visually inspect the structural diff.
- [ ] Update `AccountAvatarMenu` context behavior.
- [ ] Build.
- [ ] Update `HomeTimelineView` new-photos chip.
- [ ] Build.
- [ ] Pause for review.

### Task 4: P2 compose/floating control polish

- [ ] Review `BaseComposeView` utility bars after P1.
- [ ] Apply only the minimal accepted change.
- [ ] Build.
- [ ] Pause for review.

### Task 5: P3 local polish and verification prep

- [ ] Convert only touched navigation-adjacent `.foregroundColor` calls.
- [ ] Build.
- [ ] Generate manual review checklist for Phase 4.
- [ ] Pause for final review.

## Self-Review

- Spec coverage: Deployment target, navigation inventory findings, glass misuse, floating controls, accessibility, and out-of-scope constraints are represented.
- No placeholders: All entries identify files, line areas, planned changes, reasons, risks, and checkpoints.
- Scope check: Widget visual migration remains out of scope; deployment settings are included because iOS 26.5 is now mandatory.
