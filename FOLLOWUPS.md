# Follow-ups

## iOS 26 Migration Warnings

- `xcodebuild` on iOS 26.5 reports existing `UIScreen.main` deprecation warnings in several layout-related views/modifiers. This is outside the Liquid Glass navigation-control scope and should be handled in a separate layout modernization pass.

Observed examples from the P0 build:
- `Impressia/Modifiers/AnimatePlaceholderModifier.swift`
- `Impressia/Views/StatusesView.swift`
- `Impressia/Views/TrendStatusesView.swift`
- `Impressia/Widgets/ImageViewer.swift`
- `Impressia/Views/UserProfileView/UserProfileView.swift`
