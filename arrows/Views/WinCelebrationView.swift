//
//  WinCelebrationView.swift
//  arrows
//
//  Win celebration screen with confetti
//

import SwiftUI
import UIKit

struct WinCelebrationView: View {
    @EnvironmentObject var preferences: UserPreferences
    let onContinue: () -> Void

    @State private var opacity: CGFloat = 0
    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var showContinueButton = false
    @State private var hasContinued = false

    var body: some View {
        let colors = preferences.theme.colors

        ZStack {
            // Background
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            // Confetti
            ForEach(confettiParticles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
            }

            // Content
            VStack(spacing: 30) {
                Spacer()

                // Celebration icon
                Image(systemName: "star.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(hex: 0xFFD700))
                    .rotationEffect(.degrees(Double(opacity) * 360))

                // Random congratulation message
                Text(GameConstants.congratulationMessages.randomElement() ?? "Well Done!")
                    .font(.system(size: GameConstants.congratulationsFontSize, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Spacer()

                // Continue button
                if showContinueButton {
                    Button(action: safeContinue) {
                        HStack {
                            Text("Continue")
                                .font(.title2.bold())
                            Image(systemName: "arrow.right")
                                .font(.title2)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(colors.accent)
                        .cornerRadius(16)
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer()
                    .frame(height: 50)
            }
        }
        .opacity(opacity)
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Fade in
        withAnimation(.easeIn(duration: GameConstants.videoFadeInDuration)) {
            opacity = 1
        }

        // Generate confetti
        generateConfetti()

        // Show continue button after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring()) {
                showContinueButton = true
            }
        }

        // Auto-continue after total duration
        DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.videoTotalDuration) {
            safeContinue()
        }
    }

    private func safeContinue() {
        guard !hasContinued else { return }
        hasContinued = true
        onContinue()
    }

    private func generateConfetti() {
        for _ in 0..<100 {
            let particle = ConfettiParticle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: -20
                ),
                velocity: CGPoint(
                    x: CGFloat.random(in: -3...3),
                    y: CGFloat.random(in: 5...15)
                ),
                color: GameConstants.confettiColors.randomElement() ?? .yellow,
                size: CGFloat.random(in: 8...16)
            )
            confettiParticles.append(particle)
        }

        // Animate confetti
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            var anyVisible = false

            for i in confettiParticles.indices {
                confettiParticles[i].position.x += confettiParticles[i].velocity.x
                confettiParticles[i].position.y += confettiParticles[i].velocity.y
                confettiParticles[i].velocity.y += 0.2 // Gravity
                confettiParticles[i].velocity.x *= 0.99 // Air resistance

                if confettiParticles[i].position.y < UIScreen.main.bounds.height + 50 {
                    anyVisible = true
                }
            }

            if !anyVisible {
                timer.invalidate()
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    var velocity: CGPoint
    let color: Color
    let size: CGFloat
}

#Preview {
    WinCelebrationView(onContinue: {})
        .environmentObject(UserPreferences.shared)
}
