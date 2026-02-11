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

    var body: some View {
        let colors = preferences.theme.colors

        VStack(spacing: 40) {
            Spacer()

            // App Title
            VStack(spacing: 8) {
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(colors.accent)

                Text("Arrows")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)

                Text("Level \(preferences.levelNumber)")
                    .font(.title2)
                    .foregroundColor(colors.snake)
            }

            Spacer()

            // Play Button
            Button(action: {
                navigateTo(.game)
            }) {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.title2)
                    Text("Play")
                        .font(.title2.bold())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(colors.accent)
                .cornerRadius(16)
            }
            .padding(.horizontal, 40)

            // Settings Button
            Button(action: {
                navigateTo(.settings)
            }) {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                    Text("Settings")
                        .font(.title3)
                }
                .foregroundColor(colors.accent)
            }
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    MainMenuView(navigateTo: { _ in })
        .environmentObject(UserPreferences.shared)
        .preferredColorScheme(.dark)
}
