//
//  GeneratorView.swift
//  arrows
//
//  Custom level generator screen
//

import SwiftUI

struct GeneratorView: View {
    @EnvironmentObject var preferences: UserPreferences
    let navigateTo: (AppScreen) -> Void

    @State private var width: Float = GameConstants.generatorDefaultSize
    @State private var height: Float = GameConstants.generatorDefaultSize
    @State private var selectedShape: String = "rectangular"
    @State private var showWarning = false

    private var maxSize: Float {
        preferences.isFillBoardEnabled
            ? GameConstants.generatorMaxSizeFillBoard
            : GameConstants.generatorMaxSize
    }

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

                Text("Generator")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.left")
                    .font(.title2)
                    .opacity(0)
            }
            .padding()

            ScrollView {
                VStack(spacing: 24) {
                    // Size Section
                    SettingsSection(title: "Board Size") {
                        VStack(spacing: 16) {
                            // Width Slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Width")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(Int(width))")
                                        .foregroundColor(colors.snake)
                                        .font(.headline)
                                }
                                Slider(
                                    value: $width,
                                    in: GameConstants.generatorMinSize...maxSize,
                                    step: 1
                                )
                                .tint(colors.accent)
                            }

                            // Height Slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Height")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(Int(height))")
                                        .foregroundColor(colors.snake)
                                        .font(.headline)
                                }
                                Slider(
                                    value: $height,
                                    in: GameConstants.generatorMinSize...maxSize,
                                    step: 1
                                )
                                .tint(colors.accent)
                            }
                        }
                    }

                    // Shape Section
                    SettingsSection(title: "Board Shape") {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 70), spacing: 12)
                        ], spacing: 12) {
                            // Rectangular (default)
                            ShapeCard(
                                name: "Rectangular",
                                isSelected: selectedShape == "rectangular",
                                accentColor: colors.accent
                            ) {
                                Image(systemName: "square.grid.3x3.fill")
                                    .font(.title2)
                                    .foregroundColor(selectedShape == "rectangular" ? colors.accent : .gray)
                            }
                            .onTapGesture { selectedShape = "rectangular" }

                            // Custom shapes
                            ForEach(ShapeRegistry.shapes) { shape in
                                ShapeCard(
                                    name: shape.displayName,
                                    isSelected: selectedShape == shape.id,
                                    accentColor: colors.accent
                                ) {
                                    if let uiImage = shape.image {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 36, height: 36)
                                    } else {
                                        Text(String(shape.displayName.prefix(1)))
                                            .font(.title2.bold())
                                            .foregroundColor(.gray)
                                    }
                                }
                                .onTapGesture { selectedShape = shape.id }
                            }
                        }
                    }

                    // Generate Button
                    Button(action: { onGenerateTapped() }) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.title2)
                            Text("Generate & Start")
                                .font(.title2.bold())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(colors.accent)
                        .cornerRadius(16)
                    }
                }
                .padding()
            }

            if !preferences.isAdFree {
                BannerAdView()
                    .frame(height: 50)
            }
        }
        .onChange(of: maxSize) { newMax in
            if width > newMax { width = newMax }
            if height > newMax { height = newMax }
        }
        .alert("Discard Progress?", isPresented: $showWarning) {
            Button("Cancel", role: .cancel) {}
            Button("Proceed", role: .destructive) {
                startCustomGame()
            }
        } message: {
            Text("Starting a custom game will discard your currently saved game. Do you want to proceed?")
        }
    }

    private func onGenerateTapped() {
        if preferences.currentLevel != nil {
            showWarning = true
        } else {
            startCustomGame()
        }
    }

    private func startCustomGame() {
        let shapeName: String? = selectedShape == "rectangular" ? nil : selectedShape
        preferences.clearSavedGame()

        // Store custom config for GameEngine to pick up
        preferences.pendingCustomGame = CustomGameConfig(
            width: Int(width),
            height: Int(height),
            shapeName: shapeName
        )

        navigateTo(.game)
    }
}

// MARK: - Shape Card

struct ShapeCard<Content: View>: View {
    let name: String
    let isSelected: Bool
    let accentColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 6) {
            content
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSelected ? accentColor : Color.clear, lineWidth: 2)
                )

            Text(name)
                .font(.caption2)
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }
}

#Preview {
    GeneratorView(navigateTo: { _ in })
        .environmentObject(UserPreferences.shared)
        .preferredColorScheme(.dark)
        .background(Color(hex: 0x1E1F28))
}
