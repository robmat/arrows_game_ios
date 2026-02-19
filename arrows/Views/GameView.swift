//
//  GameView.swift
//  arrows
//
//  Main game screen
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject var preferences: UserPreferences
    @EnvironmentObject var interstitialAdManager: InterstitialAdManager
    @EnvironmentObject var rewardedAdManager: RewardedAdManager
    @StateObject private var engine = GameEngine()
    let navigateTo: (AppScreen) -> Void
    @State private var showIntro = false
    @State private var showGuidanceLines = false
    @State private var guidanceAlpha: CGFloat = 0

    var body: some View {
        let colors = preferences.theme.colors

        ZStack {
            colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar
                GameTopBar(
                    levelNumber: engine.levelNumber,
                    lives: engine.lives,
                    maxLives: engine.maxLives,
                    onBack: { navigateTo(.mainMenu) },
                    onRestart: { engine.restartLevel() },
                    onHint: { onHintRequested() }
                )
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                // Game Board
                if engine.isLoading {
                    LoadingView(progress: engine.loadingProgress)
                } else {
                    BoardView(engine: engine, guidanceAlpha: guidanceAlpha)
                        .padding()
                }

                Spacer()

                // Bottom buttons
                if !engine.isLoading {
                    HStack {
                        // Reset View button
                        Button(action: { engine.resetView() }) {
                            Image(systemName: "scope")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(colors.accent.opacity(0.3))
                                .clipShape(Circle())
                        }

                        Spacer()

                        // Guidance Lines toggle
                        Button(action: {
                            showGuidanceLines.toggle()
                            withAnimation(.easeInOut(duration: GameConstants.guidanceAnimDuration)) {
                                guidanceAlpha = showGuidanceLines ? 1 : 0
                            }
                        }) {
                            Image(systemName: "grid")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(showGuidanceLines ? colors.accent : colors.accent.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                }

                if !preferences.isAdFree {
                    BannerAdView()
                        .frame(height: 50)
                }
            }

            // Win Celebration Overlay
            if engine.isGameWon {
                WinCelebrationView(
                    onContinue: {
                        onLevelCompleted()
                    }
                )
                .transition(.opacity)
            }

            // Game Over Overlay
            if engine.isGameOver {
                GameOverView(
                    onRetry: {
                        engine.restartLevel()
                    },
                    onMainMenu: {
                        navigateTo(.mainMenu)
                    },
                    onWatchAd: preferences.isAdFree ? nil : {
                        rewardedAdManager.showAd(
                            onRewarded: { engine.grantExtraLife() },
                            onDismissed: {}
                        )
                    },
                    isAdLoaded: rewardedAdManager.isAdLoaded,
                    isAdLoading: rewardedAdManager.isAdLoading
                )
                .transition(.opacity)
            }

            // Intro Tutorial Overlay
            if showIntro {
                IntroOverlay {
                    showIntro = false
                    preferences.isIntroCompleted = true
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: engine.isGameWon)
        .animation(.easeInOut, value: engine.isGameOver)
        .animation(.easeInOut, value: showIntro)
        .onChange(of: engine.isLoading) { isLoading in
            if !isLoading && !preferences.isIntroCompleted {
                showIntro = true
            }
        }
        .onChange(of: engine.isGameWon) { isWon in
            if isWon {
                preferences.gamesCompleted += 1
            }
        }
    }

    private func onHintRequested() {
        guard !preferences.isAdFree && rewardedAdManager.isAdLoaded else {
            engine.showHint()
            return
        }
        var rewarded = false
        rewardedAdManager.showAd(
            onRewarded: { rewarded = true },
            onDismissed: { if rewarded { engine.showHint() } }
        )
    }

    private func onLevelCompleted() {
        let shouldShowInterstitial = !preferences.isAdFree
            && preferences.gamesCompleted > 0
            && preferences.gamesCompleted % AdConstants.gamesBetweenInterstitials == 0
            && interstitialAdManager.isAdLoaded

        if shouldShowInterstitial {
            interstitialAdManager.showAd {
                engine.nextLevel()
            }
        } else {
            engine.nextLevel()
        }
    }
}

// MARK: - Intro Tutorial Overlay

struct IntroOverlay: View {
    @EnvironmentObject var preferences: UserPreferences
    let onDismiss: () -> Void

    var body: some View {
        let colors = preferences.theme.colors

        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {} // consume taps

            VStack(spacing: 24) {
                Text("Tap the arrowhead\nto remove the arrow")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Button(action: onDismiss) {
                    Text("Got it!")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(colors.accent)
                        .cornerRadius(12)
                }
            }
            .padding(32)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
        }
    }
}

struct LoadingView: View {
    let progress: Float
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)
                .tint(preferences.theme.colors.accent)

            Text("Generating Level...")
                .foregroundColor(.white)
                .font(.headline)

            ProgressView(value: Double(progress))
                .progressViewStyle(LinearProgressViewStyle(tint: preferences.theme.colors.accent))
                .frame(width: 200)

            Text("\(Int(progress * 100))%")
                .foregroundColor(preferences.theme.colors.snake)

            Spacer()
        }
    }
}

struct GameOverView: View {
    @EnvironmentObject var preferences: UserPreferences
    let onRetry: () -> Void
    let onMainMenu: () -> Void
    let onWatchAd: (() -> Void)?
    let isAdLoaded: Bool
    let isAdLoading: Bool

    var body: some View {
        let colors = preferences.theme.colors

        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(CommonColors.heartRed)

                Text("Game Over")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)

                VStack(spacing: 16) {
                    if let onWatchAd {
                        WatchAdForLifeButton(
                            onWatchAd: onWatchAd,
                            isAdLoaded: isAdLoaded,
                            isAdLoading: isAdLoading,
                            accentColor: colors.accent
                        )
                    }

                    Button(action: onRetry) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Try Again")
                        }
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(colors.accent)
                        .cornerRadius(12)
                    }

                    Button(action: onMainMenu) {
                        HStack {
                            Image(systemName: "house.fill")
                            Text("Main Menu")
                        }
                        .font(.title3)
                        .foregroundColor(colors.accent)
                    }
                }
                .padding(.horizontal, 60)
            }
        }
    }
}

// MARK: - Watch Ad For Life Button

private struct WatchAdForLifeButton: View {
    let onWatchAd: () -> Void
    let isAdLoaded: Bool
    let isAdLoading: Bool
    let accentColor: Color

    private var label: String {
        if isAdLoading { return "Loading Ad..." }
        if !isAdLoaded { return "Ad Not Ready" }
        return "Watch Ad → Get a Life"
    }

    var body: some View {
        Button(action: onWatchAd) {
            HStack {
                Image(systemName: "play.rectangle.fill")
                Text(label)
            }
            .font(.title3.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(accentColor.opacity(0.6))
            .cornerRadius(12)
        }
        .disabled(!isAdLoaded || isAdLoading)
    }
}

#Preview {
    GameView(navigateTo: { _ in })
        .environmentObject(UserPreferences.shared)
        .environmentObject(InterstitialAdManager())
        .environmentObject(RewardedAdManager())
}
