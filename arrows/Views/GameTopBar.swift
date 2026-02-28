//
//  GameTopBar.swift
//  arrows
//
//  Top bar with controls and lives display
//

import SwiftUI

struct GameTopBar: View {
    @EnvironmentObject var preferences: UserPreferences
    let levelNumber: Int
    let lives: Int
    let maxLives: Int
    let onBack: () -> Void
    let onRestart: () -> Void
    let onHint: () -> Void

    var body: some View {
        HStack {
            // Back Button
            TopBarButton(icon: "chevron.left", action: onBack)

            Spacer()

            // Level Number
            Text(AppStrings.Game.levelNumber(levelNumber))
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            // Lives Display
            HeartsDisplay(lives: lives, maxLives: maxLives)

            Spacer()

            // Hint Button
            TopBarButton(icon: "lightbulb.fill", showAdBadge: !preferences.isAdFree, action: {
                print("Hint: button tapped")
                onHint()
            })

            // Restart Button
            TopBarButton(icon: "arrow.counterclockwise", action: onRestart)
        }
    }
}

struct TopBarButton: View {
    @EnvironmentObject var preferences: UserPreferences
    let icon: String
    var showAdBadge: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(preferences.theme.colors.topBarButtonBackground)
                .cornerRadius(10)
                .overlay(alignment: .topTrailing) {
                    if showAdBadge {
                        Text(AppStrings.Game.adBadge)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .background(preferences.theme.colors.accent)
                            .cornerRadius(4)
                            .offset(x: 4, y: -4)
                    }
                }
        }
    }
}

struct HeartsDisplay: View {
    let lives: Int
    let maxLives: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<maxLives, id: \.self) { index in
                Image(systemName: index < lives ? "heart.fill" : "heart")
                    .font(.system(size: 16))
                    .foregroundColor(index < lives ? CommonColors.heartRed : CommonColors.heartRed.opacity(0.3))
            }
        }
    }
}

#Preview {
    ZStack {
        Color(hex: 0x1E1F28)
            .ignoresSafeArea()

        GameTopBar(
            levelNumber: 5,
            lives: 3,
            maxLives: 5,
            onBack: {},
            onRestart: {},
            onHint: {}
        )
        .environmentObject(UserPreferences.shared)
        .padding()
    }
}
