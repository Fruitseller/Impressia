//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Modifications Copyright 2026 Piotr Großmann
//  Licensed under the Apache License 2.0.
//

import Foundation
import SwiftUI
import EnvironmentKit
import ServicesKit
import TipKit
import WidgetsKit

@MainActor
extension View {
    func navigationMenuButtons(viewMode: Binding<MainView.ViewMode>,
                               onViewModeIconTap: @escaping (MainView.ViewMode) -> Void) -> some View {
        modifier(NavigationMenuButtons(viewMode: viewMode,
                                       onViewModeIconTap: onViewModeIconTap))
    }
}

@MainActor
private struct NavigationMenuButtons: ViewModifier {
    @Environment(ApplicationState.self) var applicationState
    @Environment(RouterPath.self) var routerPath
    @Environment(\.modelContext) private var modelContext

    private let onViewModeIconTap: (MainView.ViewMode) -> Void
    private let imageFontSize = 20.0

    @State private var displayedCustomMenuItems = [
        SelectedMenuItemDetails(position: 1, viewMode: .home),
        SelectedMenuItemDetails(position: 2, viewMode: .local),
        SelectedMenuItemDetails(position: 3, viewMode: .profile)
    ]

    @State private var hiddenMenuItems: [MainView.ViewMode] = []

    @Binding var viewMode: MainView.ViewMode

    init(viewMode: Binding<MainView.ViewMode>, onViewModeIconTap: @escaping (MainView.ViewMode) -> Void) {
        self.onViewModeIconTap = onViewModeIconTap
        self._viewMode = viewMode
    }

    func body(content: Content) -> some View {
        ZStack {
            content

            VStack(alignment: .trailing) {
                Spacer()

                HStack(alignment: .center) {
                    Spacer()
                    self.menuContainerView()
                        .padding(.bottom, 10)
                    Spacer()
                }
            }
            .onAppear {
                self.loadCustomMenuItems()
            }
        }
    }

    @ViewBuilder
    private func menuContainerView() -> some View {
        GlassEffectContainer(spacing: 12) {
            HStack(alignment: .center) {
                AccountAvatarMenu(viewMode: $viewMode)

                HStack {
                    self.contextMenuView()
                    self.customMenuItemsView()
                }
                .frame(height: 50)
                .padding(.horizontal, 8)
                .glassEffect(.regular.interactive(), in: Capsule())

                self.composeImageView()
                    .frame(height: 50)
                    .padding(.horizontal, 8)
                    .glassEffect(.regular.interactive(), in: Circle())
            }
        }
    }

    @ViewBuilder
    private func contextMenuView() -> some View {
        Menu {
            MainNavigationOptions(hiddenMenuItems: $hiddenMenuItems) { viewMode in
                self.onViewModeIconTap(viewMode)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: self.imageFontSize))
                .foregroundStyle(Color.mainTextColor.opacity(0.75))
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
        }
        .environment(\.menuOrder, .fixed)
    }

    @ViewBuilder
    private func customMenuItemsView() -> some View {
        ForEach(self.displayedCustomMenuItems) { item in
            self.customMenuItemView(item)
        }
    }

    @ViewBuilder
    private func composeImageView() -> some View {
        Button {
            HapticService.shared.fireHaptic(of: .buttonPress)
            self.routerPath.presentedSheet = .newStatusEditor
        } label: {
            Image(systemName: "plus")
                .font(.system(size: self.imageFontSize))
                .foregroundStyle(Color.mainTextColor.opacity(0.75))
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
        }
    }

    @ViewBuilder
    private func customMenuItemView(_ displayedCustomMenuItem: SelectedMenuItemDetails) -> some View {
        Button {
            self.onViewModeIconTap(displayedCustomMenuItem.viewMode)
        } label: {
            displayedCustomMenuItem.viewMode.getImage(applicationState: applicationState)
                .font(.system(size: self.imageFontSize))
                .foregroundStyle(Color.mainTextColor.opacity(0.75))
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
        }.contextMenu {
            MainNavigationOptions(hiddenMenuItems: Binding.constant([])) { viewMode in
                withAnimation {
                    displayedCustomMenuItem.viewMode = viewMode
                }

                // Saving in database.
                switch displayedCustomMenuItem.position {
                case 1:
                    ApplicationSettingsHandler.shared.set(customNavigationMenuItem1: viewMode.rawValue, modelContext: modelContext)
                case 2:
                    ApplicationSettingsHandler.shared.set(customNavigationMenuItem2: viewMode.rawValue, modelContext: modelContext)
                case 3:
                    ApplicationSettingsHandler.shared.set(customNavigationMenuItem3: viewMode.rawValue, modelContext: modelContext)
                default:
                    break
                }

                self.hiddenMenuItems = self.displayedCustomMenuItems.map({ $0.viewMode })
            }
        }
    }

    private func loadCustomMenuItems() {
        let applicationSettings = ApplicationSettingsHandler.shared.get(modelContext: modelContext)

        self.setCustomMenuItem(position: 1, viewMode: MainView.ViewMode(rawValue: Int(applicationSettings.customNavigationMenuItem1)) ?? .home)
        self.setCustomMenuItem(position: 2, viewMode: MainView.ViewMode(rawValue: Int(applicationSettings.customNavigationMenuItem2)) ?? .local)
        self.setCustomMenuItem(position: 3, viewMode: MainView.ViewMode(rawValue: Int(applicationSettings.customNavigationMenuItem3)) ?? .profile)

        self.hiddenMenuItems = self.displayedCustomMenuItems.map({ $0.viewMode })
    }

    private func setCustomMenuItem(position: Int, viewMode: MainView.ViewMode) {
        if let displayedCustomMenuItem = self.displayedCustomMenuItems.first(where: { $0.position == position }) {
            displayedCustomMenuItem.viewMode = viewMode
        }
    }
}
