//
//  MainMenuView.swift
//  arrows
//
//  Main menu / home screen
//

import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var preferences: UserPreferences
    let navigateTo: (AppScreen) -> Void

    @State private var isVisible = false
    @State private var iconRotation: Double = 0
    @State private var iconPulseScale: CGFloat = 1.0
    @State private var buttonPulseScale: CGFloat = 1.0

    private var isGeneratorUnlocked: Bool {
        preferences.levelNumber >= GameConstants.generatorUnlockLevel
    }

    var body: some View {
        let colors = preferences.theme.colors

        VStack(spacing: 0) {
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 40) {
                        // App Title
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.up.right.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(colors.accent)
                                .rotationEffect(.degrees(iconRotation))
                                .scaleEffect(iconPulseScale)

                            Text(AppStrings.MainMenu.title)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)

                            Text(AppStrings.MainMenu.levelNumber(preferences.levelNumber))
                                .font(.title2)
                                .foregroundColor(colors.snake)
                        }
                        .homeEntry(isVisible: isVisible, index: 0)

                        // Play Button
                        Button(action: {
                            navigateTo(.game)
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.title2)
                                Text(AppStrings.MainMenu.play)
                                    .font(.title2.bold())
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(colors.accent)
                            .cornerRadius(16)
                        }
                        .scaleEffect(buttonPulseScale)
                        .padding(.horizontal, 40)
                        .homeEntry(isVisible: isVisible, index: 1)

                        // Generator Button
                        Button(action: {
                            navigateTo(.generator)
                        }) {
                            HStack {
                                Image(systemName: isGeneratorUnlocked ? "sparkles" : "lock.fill")
                                    .font(.title3)
                                Text(isGeneratorUnlocked ? AppStrings.MainMenu.generator : AppStrings.MainMenu.generatorLocked(GameConstants.generatorUnlockLevel))
                                    .font(.title3)
                            }
                            .foregroundColor(isGeneratorUnlocked ? colors.accent : .gray)
                        }
                        .disabled(!isGeneratorUnlocked)
                        .homeEntry(isVisible: isVisible, index: 2)

                        // Settings Button
                        Button(action: {
                            navigateTo(.settings)
                        }) {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                    .font(.title3)
                                Text(AppStrings.MainMenu.settings)
                                    .font(.title3)
                            }
                            .foregroundColor(colors.accent)
                        }
                        .homeEntry(isVisible: isVisible, index: 3)
                    }
                    .padding(.vertical, 16)
                    .frame(minHeight: geo.size.height)
                }
            }

            if !preferences.isAdFree {
                BannerAdView()
                    .frame(height: 50)
            }
        }
        .onAppear {
            isVisible = true

            withAnimation(
                .linear(duration: GameConstants.homeIconRotateDuration)
                    .repeatForever(autoreverses: false)
            ) {
                iconRotation = 360
            }

            withAnimation(
                .easeInOut(duration: GameConstants.homeIconPulseDuration)
                    .repeatForever(autoreverses: true)
            ) {
                iconPulseScale = GameConstants.homeIconPulseScale
            }

            withAnimation(
                .easeInOut(duration: GameConstants.homeButtonPulseDuration)
                    .repeatForever(autoreverses: true)
            ) {
                buttonPulseScale = GameConstants.homeButtonPulseScale
            }
        }
    }
}

#Preview {
    MainMenuView(navigateTo: { _ in })
        .environmentObject(UserPreferences.shared)
        .preferredColorScheme(.dark)
}
