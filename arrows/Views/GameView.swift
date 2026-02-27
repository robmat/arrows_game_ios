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
            .zIndex(1)

            Spacer()

            // Game Board
            if engine.isLoading {
                LoadingView(progress: engine.loadingProgress)
                    .transition(.opacity)
            } else {
                BoardView(engine: engine, guidanceAlpha: guidanceAlpha)
                    .overlay(
                        Group {
                            if showIntro {
                                GeometryReader { geo in
                                    IntroFingerView(
                                        headPosition: introFingerPosition(in: geo.size),
                                        onDismiss: { dismissIntro() }
                                    )
                                }
                                .transition(.opacity.animation(.easeInOut))
                            }
                        }
                    )
                    .transition(
                        .scale(scale: GameConstants.boardEntryScaleFrom)
                            .combined(with: .opacity)
                    )
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
                .zIndex(1)
            }

            if !preferences.isAdFree {
                BannerAdView()
                    .frame(height: 50)
            }
        }
        .background(colors.background.ignoresSafeArea())
        .overlay(
            Group {
                if engine.isGameWon {
                    WinCelebrationView(
                        onContinue: {
                            onLevelCompleted()
                        }
                    )
                    .transition(.opacity)
                }

                if engine.isGameOver {
                    GameOverView(
                        onRetry: {
                            engine.restartLevel()
                        },
                        onMainMenu: {
                            preferences.clearSavedGame()
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
            }
        )
        .onChange(of: engine.isEntryAnimating) { animating in
            if !animating && !engine.isLoading && !preferences.isIntroCompleted {
                showIntro = true
            }
        }
        .onChange(of: engine.isLoading) { isLoading in
            if isLoading {
                showIntro = false
            } else if !engine.isEntryAnimating && !preferences.isIntroCompleted {
                showIntro = true
            }
        }
        .onAppear {
            if !engine.isLoading && !engine.isEntryAnimating && !preferences.isIntroCompleted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showIntro = true
                }
            }
        }
        .onChange(of: engine.level.snakes.count) { _ in
            if showIntro { dismissIntro() }
        }
        .onChange(of: engine.lives) { _ in
            if showIntro { dismissIntro() }
        }
        .onChange(of: engine.isGameWon) { isWon in
            if isWon {
                preferences.gamesCompleted += 1
            }
        }
    }

    private func dismissIntro() {
        showIntro = false
        preferences.isIntroCompleted = true
    }

    private func introFingerPosition(in size: CGSize) -> CGPoint {
        let level = engine.level
        guard !level.snakes.isEmpty else { return .zero }

        let removableId = SolvabilityChecker.findRemovableSnake(level)
        let snake: Snake
        if let id = removableId, let found = level.snakes.first(where: { $0.id == id }) {
            snake = found
        } else if let first = level.snakes.first {
            snake = first
        } else {
            return .zero
        }

        let head = snake.head
        let margin = min(size.width, size.height) * 0.05
        let cellSize = min(
            (size.width - margin * 2) / CGFloat(level.width),
            (size.height - margin * 2) / CGFloat(level.height)
        )
        let boardWidth = cellSize * CGFloat(level.width)
        let boardHeight = cellSize * CGFloat(level.height)
        let drawOffsetX = (size.width - boardWidth) / 2
        let drawOffsetY = (size.height - boardHeight) / 2

        // Cell center in board-local coordinates
        let cx = drawOffsetX + (CGFloat(head.x) + 0.5) * cellSize
        let cy = drawOffsetY + (CGFloat(head.y) + 0.5) * cellSize

        // Offset toward arrow head (matches where drawSnake places the arrow)
        let arrowOffset = cellSize * GameConstants.arrowHeadOffset
        return CGPoint(
            x: cx + CGFloat(snake.headDirection.dx) * arrowOffset,
            y: cy + CGFloat(snake.headDirection.dy) * arrowOffset
        )
    }

    private func onHintRequested() {
        print("Hint: onHintRequested called, isAdFree=\(preferences.isAdFree), isAdLoaded=\(rewardedAdManager.isAdLoaded)")
        guard !preferences.isAdFree && rewardedAdManager.isAdLoaded else {
            print("Hint: calling engine.showHint() directly")
            engine.showHint()
            return
        }
        var rewarded = false
        print("Hint: showing rewarded ad")
        rewardedAdManager.showAd(
            onRewarded: {
                print("Hint: rewarded callback fired")
                rewarded = true
            },
            onDismissed: {
                print("Hint: ad dismissed, rewarded=\(rewarded)")
                if rewarded { engine.showHint() }
            }
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

// MARK: - Intro Tutorial Finger

struct IntroFingerView: View {
    let headPosition: CGPoint
    let onDismiss: () -> Void
    @State private var flashOpacity: Double = 1.0

    var body: some View {
        Image(systemName: "hand.point.up.left.fill")
            .font(.system(size: 52))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.7), radius: 8, x: 1, y: 1)
            .rotationEffect(.degrees(135))
            .opacity(flashOpacity)
            .position(x: headPosition.x - 28, y: headPosition.y - 10)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    flashOpacity = 0.2
                }
            }
            .onTapGesture { onDismiss() }
            .allowsHitTesting(true)
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
