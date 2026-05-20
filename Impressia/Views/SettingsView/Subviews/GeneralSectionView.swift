//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Modifications Copyright 2026 Piotr Großmann
//  Licensed under the Apache License 2.0.
//

import SwiftUI
import TipKit
import EnvironmentKit
import WidgetsKit

struct GeneralSectionView: View {
    @Environment(ApplicationState.self) var applicationState
    @Environment(\.modelContext) private var modelContext

    private let customIconNames = ["Default",
                                   "Blue",
                                   "Violet",
                                   "Orange",
                                   "Pride",
                                   "Yellow",
                                   "Gradient",
                                   "Blue-Camera",
                                   "Violet-Camera",
                                   "Orange-Camera",
                                   "Pride-Camera",
                                   "Yellow-Camera",
                                   "Gradient-Camera",
                                   "Orange-Lens",
                                   "Pink-Lens",
                                   "Blue-Lens",
                                   "Brown-Lens"]

    private let themeNames: [(theme: Theme, name: LocalizedStringKey)] = [
        (Theme.system, "settings.title.system"),
        (Theme.light, "settings.title.light"),
        (Theme.dark, "settings.title.dark")
    ]

    var body: some View {
        @Bindable var applicationState = applicationState
 
        Section("settings.title.general") {
            // Application icon.
            Picker(selection: $applicationState.activeIcon) {
                ForEach(self.customIconNames, id: \.self) { icon in
                    HStack {
                        Image("\(icon)-Preview")
                        Text(icon.replacing("-", with: " "))
                            .font(.subheadline)
                    }
                    .tag(icon)
                }
            } label: {
                Text("settings.title.applicationIcon", comment: "Application icon")
            }
            .pickerStyle(.navigationLink)
            .onChange(of: self.applicationState.activeIcon) { oldIncomeName, newIconName in
                ApplicationSettingsHandler.shared.set(activeIcon: newIconName, modelContext: modelContext)
                UIApplication.shared.setAlternateIconName(newIconName == "Default" ? nil : newIconName)
            }

            // Application theme.
            Picker(selection: $applicationState.theme) {
                ForEach(self.themeNames, id: \.theme) { item in
                    Text(item.name, comment: "Theme name")
                        .tag(item.theme)
                }
            } label: {
                Text("settings.title.theme", comment: "Theme")
            }
            .onChange(of: self.applicationState.theme) { oldTheme, newTheme in
                ApplicationSettingsHandler.shared.set(theme: newTheme, modelContext: modelContext)
            }

        }
    }
}
