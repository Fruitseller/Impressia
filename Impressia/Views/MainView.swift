//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Modifications Copyright 2026 Piotr Großmann
//  Licensed under the Apache License 2.0.
//

import SwiftUI
import UIKit
import PixelfedKit
import ServicesKit
import EnvironmentKit
import WidgetsKit

@MainActor
struct MainView: View {
    @Environment(ApplicationState.self) var applicationState
    @Environment(RouterPath.self) var routerPath
    @Environment(TipsStore.self) var tipsStore
    @Environment(\.modelContext) private var modelContext

    @State private var navBarTitle: LocalizedStringKey = ViewMode.home.title
    @State private var viewMode: ViewMode = .home {
        didSet {
            self.navBarTitle = viewMode.title
        }
    }

    public enum ViewMode: Int, Identifiable {
        case home = 1
        case local = 2
        case federated = 3
        case search = 4
        case profile = 5
        case notifications = 6
        case trendingPhotos = 7
        case trendingTags = 8
        case trendingAccounts = 9
        case bookmarks = 10
        case favourites = 11

        var id: Self {
            return self
        }
        
        public var title: LocalizedStringKey {
            switch self {
            case .home:
                return "mainview.tab.homeTimeline"
            case .trendingPhotos:
                return "mainview.tab.trendingPhotos"
            case .trendingTags:
                return "mainview.tab.trendingTags"
            case .trendingAccounts:
                return "mainview.tab.trendingAccounts"
            case .local:
                return "mainview.tab.localTimeline"
            case .federated:
                return "mainview.tab.federatedTimeline"
            case .profile:
                return "mainview.tab.userProfile"
            case .notifications:
                return "mainview.tab.notifications"
            case .search:
                return "mainview.tab.search"
            case .bookmarks:
                return "userProfile.title.bookmarks"
            case .favourites:
                return "userProfile.title.favourites"
            }
        }

        @ViewBuilder
        public func getImage(applicationState: ApplicationState) -> some View {
            switch self {
            case .home:
                Image(systemName: "house")
            case .trendingPhotos:
                Image(systemName: "photo.stack")
            case .trendingTags:
                Image(systemName: "tag")
            case .trendingAccounts:
                Image(systemName: "person.crop.rectangle.stack")
            case .local:
                Image(systemName: "building")
            case .federated:
                Image(systemName: "globe.europe.africa")
            case .profile:
                Image(systemName: "person.crop.circle")
            case .notifications:
                applicationState.amountOfNewNotifications > 0
                ? AnyView(
                    Image(systemName: "bell.badge")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(applicationState.tintColor.color().opacity(0.75), Color.mainTextColor.opacity(0.75)))
                : AnyView(Image(systemName: "bell"))
            case .search:
                Image(systemName: "magnifyingglass")
            case .bookmarks:
                Image(systemName: "bookmark")
            case .favourites:
                Image(systemName: "star")
            }
        }
    }

    var body: some View {
        @Bindable var routerPath = routerPath

        NavigationStack(path: $routerPath.path) {
            self.getMainView()
                .navigationMenuButtons(viewMode: $viewMode) { viewMode in
                    self.switchView(to: viewMode)
                }
                .navigationTitle(navBarTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    self.getTrailingGridToggleToolbarItem()
                }
                .onChange(of: tipsStore.status) { oldStatus, newStatus in
                    if newStatus == .successful {
                        withAnimation(.spring()) {
                            self.routerPath.presentedOverlay = .successPayment
                            self.tipsStore.reset()
                        }
                    }
                }
        }
    }

    @ViewBuilder
    private func getMainView() -> some View {
        switch self.viewMode {
        case .home:
            if UIDevice.isIPhone {
                HomeTimelineView()
                    .id(applicationState.account?.id ?? String.empty())
            } else {
                StatusesView(listType: .home)
                    .id(applicationState.account?.id ?? String.empty())
            }
        case .trendingPhotos:
            TrendStatusesView(accountId: applicationState.account?.id ?? String.empty())
                .id(applicationState.account?.id ?? String.empty())
        case .trendingTags:
            HashtagsView(listType: .trending)
                .id(applicationState.account?.id ?? String.empty())
        case .trendingAccounts:
            AccountsPhotoView(listType: .trending)
                .id(applicationState.account?.id ?? String.empty())
        case .local:
            StatusesView(listType: .local)
                .id(applicationState.account?.id ?? String.empty())
        case .federated:
            StatusesView(listType: .federated)
                .id(applicationState.account?.id ?? String.empty())
        case .profile:
            if let accountData = self.applicationState.account {
                UserProfileView(accountId: accountData.id,
                                accountDisplayName: accountData.displayName,
                                accountUserName: accountData.acct)
                .id(applicationState.account?.id ?? String.empty())
            }
        case .notifications:
            if let accountData = self.applicationState.account {
                NotificationsView(accountId: accountData.id)
                    .id(applicationState.account?.id ?? String.empty())
            }
        case .search:
            SearchView()
                .id(applicationState.account?.id ?? String.empty())
        case .bookmarks:
            StatusesView(listType: .bookmarks)
                .id(applicationState.account?.id ?? String.empty())
        case .favourites:
            StatusesView(listType: .favourites)
                .id(applicationState.account?.id ?? String.empty())
        }
    }

    @ToolbarContentBuilder
    private func getTrailingGridToggleToolbarItem() -> some ToolbarContent {
        if self.isGridToggleVisible {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation {
                        self.applicationState.showGridOnTimeline.toggle()
                        ApplicationSettingsHandler.shared.set(showGridOnTimeline: self.applicationState.showGridOnTimeline,
                                                              modelContext: modelContext)
                    }
                } label: {
                    Image(systemName: self.applicationState.showGridOnTimeline
                          ? "rectangle.grid.1x2.fill"
                          : "rectangle.grid.2x2.fill")
                        .foregroundColor(Color.mainTextColor)
                        .accessibilityLabel(self.applicationState.showGridOnTimeline
                                            ? "global.display.style.column"
                                            : "global.display.style.grid")
                }
            }
        }
    }

    private var isGridToggleVisible: Bool {
        switch viewMode {
        case .home:
            return UIDevice.isIPhone
        case .local, .federated, .bookmarks, .favourites:
            return true
        default:
            return false
        }
    }


    private func switchView(to newViewMode: ViewMode) {
        HapticService.shared.fireHaptic(of: .tabSelection)

        if viewMode == .search {
            self.hideKeyboard()
            self.asyncAfter(0.3) {
                self.viewMode = newViewMode
            }
        } else {
            self.viewMode = newViewMode
        }
    }
}
