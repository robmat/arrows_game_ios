//
//  ArrowsApp.swift
//  arrows
//
//  SwiftUI App entry point
//

import SwiftUI

@main
struct ArrowsApp: App {
    @StateObject private var preferences = UserPreferences.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferences)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var preferences: UserPreferences
    @State private var currentScreen: AppScreen = .mainMenu

    var body: some View {
        ZStack {
            preferences.theme.colors.background
                .ignoresSafeArea()

            switch currentScreen {
            case .mainMenu:
                MainMenuView(navigateTo: { currentScreen = $0 })
            case .game:
                GameView(navigateTo: { currentScreen = $0 })
            case .settings:
                SettingsView(navigateTo: { currentScreen = $0 })
            }
        }
        .preferredColorScheme(.dark)
    }
}

enum AppScreen {
    case mainMenu
    case game
    case settings
}
