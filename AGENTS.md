# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Project Overview

Impressia (formerly Vernissage) is a SwiftUI iOS/iPadOS Pixelfed client focused on photo timelines. This fork uses bundle id `io.github.fruitseller.impressia` (with `.share` and `.widget` siblings) and app group `group.io.github.fruitseller.impressia`.

- Min deployment: iOS 17 (uses `@Observable`, SwiftData, TipKit, BackgroundTasks)
- Swift tools: 5.9, Swift language version 5.0
- Devices: iPhone + iPad (`TARGETED_DEVICE_FAMILY = "1,2"`)
- Open `Impressia.xcodeproj` in Xcode 15+ (string catalogs require Xcode 15)

## Build / Run / Test

There is no Makefile or CI script — everything goes through Xcode.

```bash
# Build the app for the simulator
xcodebuild -project Impressia.xcodeproj -scheme Impressia \
  -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run all SPM package tests for one module (test targets are stubs today)
xcodebuild -project Impressia.xcodeproj -scheme Impressia \
  -destination 'platform=iOS Simulator,name=iPhone 15' test
```

Schemes: `Impressia` (app), `ImpressiaShareExtension`, `ImpressiaWidgetExtension`.

The five SPM packages (`PixelfedKit`, `ClientKit`, `EnvironmentKit`, `ServicesKit`, `WidgetsKit`) each have an XCTest target, but they are currently empty stubs — running `swift test` in a package directory works but verifies nothing meaningful.

When forking, the README notes you must change the development team and bundle id to build & sign.

## Architecture

The app is split into the main app target plus two extensions and five local Swift packages. Dependencies flow strictly upward; never introduce a back-edge.

```
PixelfedKit  ← raw Pixelfed/Mastodon REST client (OAuthSwift + HTML2Markdown)
   ↑
ClientKit    ← thin `Client` facade exposing typed services (trends, statuses, …)
   ↑
EnvironmentKit ← `ApplicationState` (@Observable singleton), shared models, theme
   ↑                                ↑
ServicesKit (Drops, Nuke)     WidgetsKit (Nuke, EmojiText) — shared SwiftUI views
   ↑                                ↑
                main app target  ─┘
```

- `PixelfedKit/Sources/PixelfedKit/Targets/*.swift` define each REST endpoint group; `Networking/TargetType.swift` is the request abstraction. `PixelfedClient+*.swift` files extend the client per area.
- `ClientKit/Sources/ClientKit/Client.swift` exposes the authenticated client as a single `@Observable` singleton with computed service properties (`Client.shared.statuses`, `.timelines`, etc.). All app code goes through `Client.shared` rather than instantiating `PixelfedClient` directly.
- `EnvironmentKit/.../ApplicationState.swift` is the global `@Observable` singleton injected via `.environment(applicationState)` in `ImpressiaApp.swift`. Theme, tint, account, badge counts, haptic preferences live here. Persistent settings live in SwiftData (`CoreData/ApplicationSettings.swift`) and are loaded into `ApplicationState` on launch.
- `WidgetsKit` holds reusable SwiftUI components (image carousels, status views) used by both the app and the widget extension — be careful when adding app-only dependencies here.

### Persistence

Despite the directory name, `CoreData/` contains **SwiftData** models, not Core Data. `Vernissage.xcdatamodeld` is a legacy artifact retained for migration. `SwiftDataHandler.shared.sharedModelContainer` is the single `ModelContainer` used app-wide, with schema: `ApplicationSettings`, `AccountData`, `ViewedStatus`, `AccountRelationship`. Each entity has a paired `*Handler` for queries. Pass `modelContext` explicitly into services rather than reaching for the container.

### Navigation

Navigation is centralized in `Impressia/Services/RouterPath.swift` and `Impressia/AppRouteur.swift`. `RouterPath` is an `@Observable` holding `path: [RouteurDestinations]`, plus `presentedSheet`, `presentedOverlay`, `presentedAlert`. View modifiers `withAppRouteur()`, `withSheetDestinations()`, `withOverlayDestinations()`, `withAlertDestinations()` wire the destination enums to concrete views. To add a screen: add a case to the relevant enum, then wire it in `AppRouteur.swift` — do not push views ad hoc with `NavigationLink`.

### Top-level app flow

`ImpressiaApp.swift` switches on `ApplicationViewMode { .loading, .signIn, .mainView }`. On launch it: configures TipKit, sets the Nuke `ImagePipeline` (custom `DataCache`, no URLSession disk cache), loads settings from SwiftData, refreshes OAuth tokens once per day, then verifies the stored account via `AuthorizationService`. A 120s foreground timer plus `.onChange(of: phase)` + `BGAppRefreshTask` keep the new-photos / new-notifications badges fresh.

### Extensions & shared container

- `ImpressiaShare/` — share extension target.
- `ImpressiaWidget/` — widget bundle with `PhotoWidget` and `QRCodeWidget`. Widgets read from the shared SwiftData store, so any schema change in `CoreData/` must be safe for the widget process too.

## Localization

The project uses Xcode 15 String Catalogs (`Localizable.xcstrings`) — there are six separate catalogs, one per module:

```
Localization/Localizable.xcstrings
EnvironmentKit/Sources/EnvironmentKit/Localizable.xcstrings
WidgetsKit/Sources/WidgetsKit/Localizable.xcstrings
ServicesKit/Sources/ServicesKit/Localizable.xcstrings
PixelfedKit/Sources/PixelfedKit/Localizable.xcstrings
ClientKit/Sources/ClientKit/Localizable.xcstrings
```

Add a new string in the catalog of the module that *uses* it, not the app catalog. Editing requires Xcode 15+; there is no good external tool today.

## Style

`.swiftlint.yml` is checked in, but SwiftLint is **not** wired into the build (see "Technical debt" in README). Still, follow its limits: line 180, file 1000, function body 100, cyclomatic 20; `shorthand_operator` and `nesting` disabled.

## Conventions to preserve

- Singletons (`Client.shared`, `ApplicationState.shared`, `SwiftDataHandler.shared`, the various `*Handler.shared`) are the established pattern — don't "modernize" them away without a plan; `ApplicationState` is wired into the SwiftUI environment, not injected via DI.
- The README's "Technical debt" list (no ViewModels, no auto-generated resources, no SwiftLint integration) is intentional for v1; treat changes in those areas as larger refactors that need discussion.

## License & attribution (Apache 2.0)

This repo is a fork of [Impressia](https://github.com/Impressia/Impressia) (Apache License 2.0, © Marcin Czachurski et al.). Apache 2.0 §4 has hard rules — follow them.

### Never touch
- `LICENSE` — keep the original, unchanged.
- Existing copyright/license headers in existing files — even on heavy rewrites, **do not remove**. Apache 2.0 §4(c) requires they be retained.
- The original `NOTICE` file (if present) — only append, never replace.
- The fork-attribution block at the top of `README.md` — even if the README is otherwise rewritten, this block stays.

### New files (written from scratch, not derived from upstream)
Add this header at the top:
```swift
// Copyright <YEAR> Piotr Großmann
// Licensed under the Apache License, Version 2.0
```

### Substantial changes to existing upstream files
**Keep** the original header and add a `Modifications` line below it:
```swift
// Modifications Copyright <YEAR> Piotr Großmann
```
(Apache 2.0 §4(b) requires "prominent notices" on modified files. Git history is the real record; the header is belt-and-suspenders.)

### NOTICE file
Not present yet. On larger restructures, create `NOTICE` with:
```
Impressia
Copyright <YEAR> Marcin Czachurski and contributors

This product includes software developed by the Impressia project.

Modifications Copyright <YEAR> Piotr Großmann
```

### Trademark / branding (not licensing, but related)
- App name "Impressia", icon, and the `dev.mczachurski.vernissage` bundle id belong to upstream.
- Fine for a private GitHub fork.
- **Before any App Store submission:** rename the app, swap the icon, change the bundle id. Apache 2.0 §6 does not grant trademark rights.

### Source headers in this repo
Existing files carry `Copyright © 2023 Marcin Czachurski and the repository contributors. Licensed under the Apache License 2.0.` — preserve it on edits per the rules above.
