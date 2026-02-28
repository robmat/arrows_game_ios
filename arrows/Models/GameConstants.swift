//
//  GameConstants.swift
//  arrows
//
//  Game constants and configuration values
//

import Foundation
import SwiftUI

enum GameConstants {
    // MARK: - Game Progression
    static let generatorUnlockLevel = 20

    // MARK: - Level Generation
    static let defaultStraightPreference: Float = 0.90
    static let maxFillBoardSize = 35
    static let firstSnakeMaxAttempts = 100

    // MARK: - Custom Generator
    static let generatorMinSize: Float = 20
    static let generatorMaxSize: Float = 100
    static let generatorMaxSizeFillBoard: Float = 35
    static let generatorDefaultSize: Float = 35

    // MARK: - Game Flow & Animations
    static let gameWonExitDelay: TimeInterval = 3.0
    static let guidanceAnimDuration: TimeInterval = 0.5

    // MARK: - Snake Removal Animation
    static let removalFrameDelay: TimeInterval = 0.016 // ~60fps
    static let removalDurationHigh: TimeInterval = 0.3
    static let removalDurationMedium: TimeInterval = 0.6
    static let removalDurationLow: TimeInterval = 0.9

    // MARK: - Board Rendering
    static let boardBorderWidth: CGFloat = 2
    static let guidanceLineAlphaFactor: CGFloat = 0.4
    static let guidanceDashOn: CGFloat = 10
    static let guidanceDashOff: CGFloat = 10
    static let snakeTailWidth: CGFloat = 0.08         // Tail/body stroke width (relative to cell size)
    static let boardCornerRadiusFactor: CGFloat = 0.3
    static let arrowHeadStrokeWidthFactor: CGFloat = 0.3
    static let flashDuration: TimeInterval = 3.0
    static let flashPulseDuration: TimeInterval = 0.25
    static let flashMinAlpha: CGFloat = 0.2
    static let arrowHeadCenterFactor: CGFloat = 0.5

    // MARK: - Arrow Direction Angles
    static let angleUp: Double = 270.0
    static let angleDown: Double = 90.0
    static let angleLeft: Double = 180.0
    static let angleRight: Double = 0.0
    static let angleTriangleOffset: Double = 2.094 // 120 degrees in radians

    // MARK: - Arrow Head Sizing
    static let arrowHeadLength: CGFloat = 0.18      // Length of arrow head (relative to cell size)
    static let arrowHeadWidth: CGFloat = 0.12       // Width of arrow head base (relative to cell size)
    static let arrowHeadOffset: CGFloat = 0.35      // Distance from cell center to arrow head tip
    static let tailEndOffset: CGFloat = 0.35        // Distance from cell center where tail ends (should meet arrow base)
    static let arrowHeadPullBack: CGFloat = 0.08    // Pull arrowhead back opposite to its direction (relative to cell size)
    static let singleCellTailShrink: CGFloat = 0.1  // Shorten single-cell arrow tail (0 = full length, >0 = shorter, relative to cell size)

    // MARK: - Input Handling
    static let cellCenter: CGFloat = 0.5
    static let tapAreaOffsetFactor: CGFloat = 0.3
    static let defaultTolerance: CGFloat = 1.3

    // MARK: - Win Celebration
    static let winVideosCount = 26
    static let videoFadeInDuration: TimeInterval = 1.0
    static let videoDisplayDuration: TimeInterval = 3.0
    static let videoFadeOutDuration: TimeInterval = 1.0
    static let videoTotalDuration: TimeInterval = 5.0
    static let congratulationsFontSize: CGFloat = 32

    // MARK: - Home Screen Animations
    static let homeEnterDuration: TimeInterval = 0.4
    static let homeStaggerDelay: TimeInterval = 0.12
    static let homeEnterOffset: CGFloat = 60
    static let homeIconRotateDuration: TimeInterval = 8.0
    static let homeIconPulseDuration: TimeInterval = 1.8
    static let homeIconPulseScale: CGFloat = 1.12
    static let homeButtonPulseDuration: TimeInterval = 1.4
    static let homeButtonPulseScale: CGFloat = 1.03

    // MARK: - Settings Screen Animations
    static let settingsEnterDuration: TimeInterval = 0.35
    static let settingsStaggerDelay: TimeInterval = 0.1
    static let settingsEnterOffset: CGFloat = 80

    // MARK: - Generator Screen Animations
    static let generatorEnterDuration: TimeInterval = 0.35
    static let generatorStaggerDelay: TimeInterval = 0.08
    static let generatorEnterOffset: CGFloat = 40
    static let generatorButtonPulseDuration: TimeInterval = 1.2
    static let generatorButtonPulseScale: CGFloat = 1.04
    static let generatorValueBounceScale: CGFloat = 1.3
    static let generatorValueBounceHold: TimeInterval = 0.08
    static let generatorShapeSelectedScale: CGFloat = 1.08
    static let generatorShapePopInStagger: TimeInterval = 0.04

    // MARK: - Board Entry Animations
    static let boardEntryScaleFrom: CGFloat = 0.92
    static let snakeEntryDuration: TimeInterval = 0.45
    static let snakeEntryStagger: TimeInterval = 0.05

    // MARK: - Confetti Colors
    static let confettiColors: [Color] = [
        Color(hex: 0xfce18a),
        Color(hex: 0xff726d),
        Color(hex: 0xf4306d),
        Color(hex: 0xb48def)
    ]

    // MARK: - Congratulation Messages
    static var congratulationMessages: [String] { AppStrings.Congratulations.all }
}

// MARK: - Color Extension
extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}
