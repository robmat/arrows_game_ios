//
//  GameView.swift
//  arrows
//
//  Main game screen
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject var preferences: UserPreferences
    @StateObject private var engine = GameEngine()
    let navigateTo: (AppScreen) -> Void

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
                    onHint: { engine.showHint() }
                )
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                // Game Board
                if engine.isLoading {
                    LoadingView(progress: engine.loadingProgress)
                } else {
                    BoardView(engine: engine)
                        .padding()
                }

                Spacer()
            }

            // Win Celebration Overlay
            if engine.isGameWon {
                WinCelebrationView(
                    onContinue: {
                        engine.nextLevel()
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
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: engine.isGameWon)
        .animation(.easeInOut, value: engine.isGameOver)
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

#Preview {
    GameView(navigateTo: { _ in })
        .environmentObject(UserPreferences.shared)
}
