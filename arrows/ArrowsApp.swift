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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferences)
                .environmentObject(interstitialAdManager)
                .environmentObject(rewardedAdManager)
                .onAppear {
                    guard !preferences.isAdFree else { return }
                    DispatchQueue.global(qos: .utility).async {
                        MobileAds.initialize()
                        DispatchQueue.main.async {
                            interstitialAdManager.loadAd()
                            rewardedAdManager.loadAd()
                        }
                    }
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var preferences: UserPreferences
    @State private var currentScreen: AppScreen = .mainMenu
    @State private var screenWidth: CGFloat = UIScreen.main.bounds.width

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
        .frame(maxWidth: screenWidth)
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            let newWidth = UIScreen.main.bounds.width
            if abs(newWidth - screenWidth) > 1 {
                screenWidth = newWidth
            }
        }
    }
}

enum AppScreen {
    case mainMenu
    case game
    case settings
    case generator
}
