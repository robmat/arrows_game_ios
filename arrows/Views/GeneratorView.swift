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

    @State private var isVisible = false
    @State private var buttonPulseScale: CGFloat = 1.0
    @State private var widthValueScale: CGFloat = 1.0
    @State private var heightValueScale: CGFloat = 1.0

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

                Text(AppStrings.Generator.title)
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
                    // Size Section — Width
                    SettingsSection(title: AppStrings.Generator.boardSize) {
                        VStack(spacing: 16) {
                            // Width Slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(AppStrings.Generator.width)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(Int(width))")
                                        .foregroundColor(colors.snake)
                                        .font(.headline)
                                        .scaleEffect(widthValueScale)
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
                                    Text(AppStrings.Generator.height)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(Int(height))")
                                        .foregroundColor(colors.snake)
                                        .font(.headline)
                                        .scaleEffect(heightValueScale)
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
                    .generatorEntry(isVisible: isVisible, index: 0)

                    // Shape Section
                    SettingsSection(title: AppStrings.Generator.boardShape) {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 70), spacing: 12)
                        ], spacing: 12) {
                            // Rectangular (default)
                            ShapeCard(
                                name: AppStrings.Generator.rectangular,
                                isSelected: selectedShape == "rectangular",
                                accentColor: colors.accent,
                                popInDelay: 0
                            ) {
                                Image(systemName: "square.grid.3x3.fill")
                                    .font(.title2)
                                    .foregroundColor(selectedShape == "rectangular" ? colors.accent : .gray)
                            }
                            .onTapGesture { selectedShape = "rectangular" }

                            // Custom shapes
                            ForEach(Array(ShapeRegistry.shapes.enumerated()), id: \.element.id) { index, shape in
                                ShapeCard(
                                    name: shape.displayName,
                                    isSelected: selectedShape == shape.id,
                                    accentColor: colors.accent,
                                    popInDelay: GameConstants.generatorShapePopInStagger * Double(index + 1)
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
                    .generatorEntry(isVisible: isVisible, index: 1)

                    // Generate Button
                    Button(action: { onGenerateTapped() }) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.title2)
                            Text(AppStrings.Generator.generateAndStart)
                                .font(.title2.bold())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(colors.accent)
                        .cornerRadius(16)
                    }
                    .scaleEffect(buttonPulseScale)
                    .generatorEntry(isVisible: isVisible, index: 2)
                }
                .padding()
            }

            if !preferences.isAdFree {
                BannerAdView()
                    .frame(height: 50)
            }
        }
        .onAppear {
            isVisible = true

            withAnimation(
                .easeInOut(duration: GameConstants.generatorButtonPulseDuration)
                    .repeatForever(autoreverses: true)
            ) {
                buttonPulseScale = GameConstants.generatorButtonPulseScale
            }
        }
        .onChange(of: Int(width)) { _ in
            bounceValue($widthValueScale)
        }
        .onChange(of: Int(height)) { _ in
            bounceValue($heightValueScale)
        }
        .onChange(of: maxSize) { newMax in
            if width > newMax { width = newMax }
            if height > newMax { height = newMax }
        }
        .alert(AppStrings.Generator.discardProgress, isPresented: $showWarning) {
            Button(AppStrings.Generator.cancel, role: .cancel) {}
            Button(AppStrings.Generator.proceed, role: .destructive) {
                startCustomGame()
            }
        } message: {
            Text(AppStrings.Generator.discardMessage)
        }
    }

    private func bounceValue(_ scale: Binding<CGFloat>) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            scale.wrappedValue = GameConstants.generatorValueBounceScale
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.generatorValueBounceHold) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                scale.wrappedValue = 1.0
            }
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
    var popInDelay: TimeInterval = 0
    @ViewBuilder let content: Content

    @State private var hasPopped = false

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
                .scaleEffect(isSelected ? GameConstants.generatorShapeSelectedScale : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isSelected)

            Text(name)
                .font(.caption2)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .scaleEffect(hasPopped ? 1.0 : 0.01)
        .animation(.spring(response: 0.35, dampingFraction: 0.6).delay(popInDelay), value: hasPopped)
        .onAppear { hasPopped = true }
    }
}

#Preview {
    GeneratorView(navigateTo: { _ in })
        .environmentObject(UserPreferences.shared)
        .preferredColorScheme(.dark)
        .background(Color(hex: 0x1E1F28))
}
