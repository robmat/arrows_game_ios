//
//  ThemeColors.swift
//  arrows
//
//  App theme colors and color schemes
//

import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case dark = "Dark"
    case green = "Green"
    case red = "Red"
    case yellow = "Yellow"
    case orange = "Orange"
    case blackAndWhite = "Black & White"

    var id: String { rawValue }

    var colors: ThemeColors {
        switch self {
        case .dark: return ThemeColors.dark
        case .green: return ThemeColors.green
        case .red: return ThemeColors.red
        case .yellow: return ThemeColors.yellow
        case .orange: return ThemeColors.orange
        case .blackAndWhite: return ThemeColors.blackAndWhite
        }
    }
}

struct ThemeColors {
    let background: Color
    let accent: Color
    let snake: Color
    let bottomBarBackground: Color
    let inactiveIcon: Color
    let topBarButtonBackground: Color

    static let dark = ThemeColors(
        background: Color(hex: 0x1E1F28),
        accent: Color(hex: 0x5B7BFE),
        snake: Color(hex: 0xA9B1FF),
        bottomBarBackground: Color(hex: 0x2A2C3E),
        inactiveIcon: Color(hex: 0x6C6E85),
        topBarButtonBackground: Color(hex: 0x3E4155)
    )

    static let green = ThemeColors(
        background: Color(hex: 0x1B2E1B),
        accent: Color(hex: 0x4CAF50),
        snake: Color(hex: 0xA8E6CF),
        bottomBarBackground: Color(hex: 0x1B2E1B).opacity(0.9),
        inactiveIcon: Color(hex: 0x6C6E85),
        topBarButtonBackground: Color(hex: 0x2A4A2A)
    )

    static let red = ThemeColors(
        background: Color(hex: 0x2E1B1B),
        accent: Color(hex: 0xE91E63),
        snake: Color(hex: 0xFF8A80),
        bottomBarBackground: Color(hex: 0x2E1B1B).opacity(0.9),
        inactiveIcon: Color(hex: 0x6C6E85),
        topBarButtonBackground: Color(hex: 0x4A2A2A)
    )

    static let yellow = ThemeColors(
        background: Color(hex: 0x2E2E1B),
        accent: Color(hex: 0xFFEB3B),
        snake: Color(hex: 0xFFF176),
        bottomBarBackground: Color(hex: 0x2E2E1B).opacity(0.9),
        inactiveIcon: Color(hex: 0x6C6E85),
        topBarButtonBackground: Color(hex: 0x4A4A2A)
    )

    static let orange = ThemeColors(
        background: Color(hex: 0x2E241B),
        accent: Color(hex: 0xFF9800),
        snake: Color(hex: 0xFFB74D),
        bottomBarBackground: Color(hex: 0x2E241B).opacity(0.9),
        inactiveIcon: Color(hex: 0x6C6E85),
        topBarButtonBackground: Color(hex: 0x4A3A2A)
    )

    static let blackAndWhite = ThemeColors(
        background: Color.black,
        accent: Color.white,
        snake: Color(hex: 0xE0E0E0),
        bottomBarBackground: Color.black.opacity(0.9),
        inactiveIcon: Color(hex: 0x6C6E85),
        topBarButtonBackground: Color(hex: 0x333333)
    )
}

// Common colors
enum CommonColors {
    static let heartRed = Color(hex: 0xFF5252)
    static let progressBarGreen = Color(hex: 0x00E676)
    static let flashingRed = Color.red
    static let white = Color.white
    static let lightGray = Color(hex: 0xD3D3D3)
}
