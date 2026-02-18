//
//  SettingsView.swift
//  arrows
//
//  Settings screen
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var preferences: UserPreferences
    let navigateTo: (AppScreen) -> Void
    @State private var showResetConfirmation = false

    var body: some View {
        let colors = preferences.theme.colors

        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { navigateTo(.mainMenu) }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(colors.accent)
                }

                Spacer()

                Text("Settings")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Spacer()

                // Invisible spacer for centering
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .opacity(0)
            }
            .padding()

            ScrollView {
                VStack(spacing: 24) {
                    // Theme Section
                    SettingsSection(title: "Appearance") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Theme")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(AppTheme.allCases) { theme in
                                        ThemeButton(
                                            theme: theme,
                                            isSelected: preferences.theme == theme,
                                            action: { preferences.theme = theme }
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // Gameplay Section
                    SettingsSection(title: "Gameplay") {
                        VStack(spacing: 16) {
                            // Animation Speed
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Animation Speed")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                Picker("Animation Speed", selection: $preferences.animationSpeed) {
                                    ForEach(AnimationSpeed.allCases, id: \.self) { speed in
                                        Text(speed.rawValue).tag(speed)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }

                            // Arrow Thickness
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Arrow Thickness")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                Picker("Arrow Thickness", selection: $preferences.arrowThickness) {
                                    ForEach(ArrowThickness.allCases, id: \.self) { thickness in
                                        Text(thickness.rawValue).tag(thickness)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }

                            // Vibration Toggle
                            SettingsToggle(
                                title: "Vibration",
                                icon: "iphone.radiowaves.left.and.right",
                                isOn: $preferences.isVibrationEnabled
                            )

                            // Sound Toggle
                            SettingsToggle(
                                title: "Sound Effects",
                                icon: "speaker.wave.2.fill",
                                isOn: $preferences.isSoundsEnabled
                            )

                            // Win Videos Toggle
                            SettingsToggle(
                                title: "Win videos",
                                icon: "film.fill",
                                isOn: $preferences.isWinVideosEnabled
                            )

                            // Fill Board Toggle
                            SettingsToggle(
                                title: "Fill board (slower)",
                                icon: "square.grid.4x3.fill",
                                isOn: $preferences.isFillBoardEnabled
                            )
                        }
                    }

                    // Progress Section
                    SettingsSection(title: "Progress") {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "flag.fill")
                                    .foregroundColor(colors.accent)
                                Text("Current Level")
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(preferences.levelNumber)")
                                    .foregroundColor(colors.snake)
                                    .font(.headline)
                            }

                            Button(action: { showResetConfirmation = true }) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Reset Progress")
                                }
                                .foregroundColor(CommonColors.heartRed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(CommonColors.heartRed.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                    }

                    // About Section
                    SettingsSection(title: "About") {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Version")
                                    .foregroundColor(.white)
                                Spacer()
                                Text("1.0")
                                    .foregroundColor(.gray)
                            }

                            HStack {
                                Text("Based on")
                                    .foregroundColor(.white)
                                Spacer()
                                Text("Arrows Android")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .alert("Reset Progress", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                preferences.resetProgress()
            }
        } message: {
            Text("This will reset your progress to Level 1. Are you sure?")
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            content
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
        }
    }
}

struct SettingsToggle: View {
    @EnvironmentObject var preferences: UserPreferences
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(preferences.theme.colors.accent)
                Text(title)
                    .foregroundColor(.white)
            }
        }
        .tint(preferences.theme.colors.accent)
    }
}

struct ThemeButton: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.colors.background)
                    .frame(width: 50, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                isSelected ? theme.colors.accent : Color.clear,
                                lineWidth: 3
                            )
                    )
                    .overlay(
                        Circle()
                            .fill(theme.colors.snake)
                            .frame(width: 20, height: 20)
                    )

                Text(theme.rawValue)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    SettingsView(navigateTo: { _ in })
        .environmentObject(UserPreferences.shared)
        .preferredColorScheme(.dark)
        .background(Color(hex: 0x1E1F28))
}
