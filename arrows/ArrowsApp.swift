//
//  ArrowsApp.swift
//  arrows
//
//  SwiftUI App entry point
//

import GoogleMobileAds
import SwiftUI

@main
struct ArrowsApp: App {
    @StateObject private var preferences = UserPreferences.shared
    @StateObject private var interstitialAdManager = InterstitialAdManager()
    @StateObject private var rewardedAdManager = RewardedAdManager()

    init() {
        MobileAds.initialize()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferences)
                .environmentObject(interstitialAdManager)
                .environmentObject(rewardedAdManager)
                .onAppear {
                    if !preferences.isAdFree {
                        interstitialAdManager.loadAd()
                        rewardedAdManager.loadAd()
                    }
                }
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
            case .generator:
                GeneratorView(navigateTo: { currentScreen = $0 })
            }
        }
        .preferredColorScheme(.dark)
    }
}

enum AppScreen {
    case mainMenu
    case game
    case settings
    case generator
}
