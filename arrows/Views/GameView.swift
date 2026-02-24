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
    @State private var boardFrame: CGRect = .zero

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
                        .background(GeometryReader { geo in
                            Color.clear.preference(
                                key: BoardFrameKey.self,
                                value: geo.frame(in: .named("gameRoot"))
                            )
                        })
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

            // Intro Tutorial Finger
            if showIntro && !boardFrame.isEmpty {
                IntroFingerView(
                    headPosition: headScreenPosition(in: boardFrame),
                    onDismiss: { dismissIntro() }
                )
                .transition(.opacity.animation(.easeInOut))
            }
        }
        .coordinateSpace(name: "gameRoot")
        .onPreferenceChange(BoardFrameKey.self) { boardFrame = $0 }
        .animation(.easeInOut, value: engine.isGameWon)
        .animation(.easeInOut, value: engine.isGameOver)
        .onChange(of: engine.isLoading) { isLoading in
            if !isLoading && !preferences.isIntroCompleted {
                showIntro = true
            }
        }
        .onChange(of: engine.level.snakes.count) { _ in
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

    private func headScreenPosition(in frame: CGRect) -> CGPoint {
        guard let snake = engine.level.snakes.first else { return .zero }
        let head = snake.head
        let level = engine.level
        let size = frame.size
        let margin = min(size.width, size.height) * 0.05
        let cellSize = min(
            (size.width - margin * 2) / CGFloat(level.width),
            (size.height - margin * 2) / CGFloat(level.height)
        )
        let boardWidth = cellSize * CGFloat(level.width)
        let boardHeight = cellSize * CGFloat(level.height)
        let drawOffsetX = (size.width - boardWidth) / 2
        let drawOffsetY = (size.height - boardHeight) / 2
        let cx = drawOffsetX + (CGFloat(head.x) + 0.5) * cellSize
        let cy = drawOffsetY + (CGFloat(head.y) + 0.5) * cellSize
        return CGPoint(x: frame.minX + cx, y: frame.minY + cy)
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

// MARK: - Board Frame Preference Key

private struct BoardFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - Intro Tutorial Finger

struct IntroFingerView: View {
    let headPosition: CGPoint
    let onDismiss: () -> Void
    @State private var tiltAngle: Double = 120

    var body: some View {
        Image(systemName: "hand.point.up.left.fill")
            .font(.system(size: 52))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.7), radius: 8, x: 1, y: 1)
            .rotationEffect(.degrees(tiltAngle))
            // Offset so the finger tip aligns above the head (tip ~26pt below icon center after rotation)
            .position(x: headPosition.x, y: headPosition.y - 52)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                    tiltAngle = 150
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
