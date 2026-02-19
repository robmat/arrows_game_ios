//
//  UserPreferences.swift
//  arrows
//
//  User preferences and game state persistence
//

import Foundation
import SwiftUI
import Combine

enum AnimationSpeed: String, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

enum ArrowThickness: String, CaseIterable {
    case thin = "Thin"
    case medium = "Medium"
    case thick = "Thick"

    var widthFactor: CGFloat {
        switch self {
        case .thin: return 0.08
        case .medium: return 0.14
        case .thick: return 0.20
        }
    }

    var headScaleFactor: CGFloat {
        switch self {
        case .thin: return 0.9
        case .medium: return 1.3
        case .thick: return 1.8
        }
    }
}

class UserPreferences: ObservableObject {
    static let shared = UserPreferences()

    private let defaults: UserDefaults

    // MARK: - Keys
    private enum Keys {
        static let levelNumber = "levelNumber"
        static let theme = "theme"
        static let animationSpeed = "animationSpeed"
        static let isVibrationEnabled = "isVibrationEnabled"
        static let isSoundsEnabled = "isSoundsEnabled"
        static let isFillBoardEnabled = "isFillBoardEnabled"
        static let initialLevel = "initialLevel"
        static let currentLevel = "currentLevel"
        static let maxLives = "maxLives"
        static let currentLives = "currentLives"
        static let isIntroCompleted = "isIntroCompleted"
        static let isWinVideosEnabled = "isWinVideosEnabled"
        static let arrowThickness = "arrowThickness"
        static let isAdFree = "isAdFree"
        static let rewardAdCount = "rewardAdCount"
        static let gamesCompleted = "gamesCompleted"
    }

    // MARK: - Published Properties
    @Published var levelNumber: Int {
        didSet { defaults.set(levelNumber, forKey: Keys.levelNumber) }
    }

    @Published var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
    }

    @Published var animationSpeed: AnimationSpeed {
        didSet { defaults.set(animationSpeed.rawValue, forKey: Keys.animationSpeed) }
    }

    @Published var isVibrationEnabled: Bool {
        didSet { defaults.set(isVibrationEnabled, forKey: Keys.isVibrationEnabled) }
    }

    @Published var isSoundsEnabled: Bool {
        didSet { defaults.set(isSoundsEnabled, forKey: Keys.isSoundsEnabled) }
    }

    @Published var isFillBoardEnabled: Bool {
        didSet { defaults.set(isFillBoardEnabled, forKey: Keys.isFillBoardEnabled) }
    }

    @Published var isWinVideosEnabled: Bool {
        didSet { defaults.set(isWinVideosEnabled, forKey: Keys.isWinVideosEnabled) }
    }

    @Published var arrowThickness: ArrowThickness {
        didSet { defaults.set(arrowThickness.rawValue, forKey: Keys.arrowThickness) }
    }

    @Published var isAdFree: Bool {
        didSet { defaults.set(isAdFree, forKey: Keys.isAdFree) }
    }

    @Published var rewardAdCount: Int {
        didSet { defaults.set(rewardAdCount, forKey: Keys.rewardAdCount) }
    }

    var gamesCompleted: Int {
        get { defaults.integer(forKey: Keys.gamesCompleted) }
        set { defaults.set(newValue, forKey: Keys.gamesCompleted) }
    }

    var initialLevel: GameLevel? {
        get {
            guard let data = defaults.data(forKey: Keys.initialLevel) else { return nil }
            return try? JSONDecoder().decode(GameLevel.self, from: data)
        }
        set {
            if let newValue = newValue, let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.initialLevel)
            } else {
                defaults.removeObject(forKey: Keys.initialLevel)
            }
        }
    }

    var currentLevel: GameLevel? {
        get {
            guard let data = defaults.data(forKey: Keys.currentLevel) else { return nil }
            return try? JSONDecoder().decode(GameLevel.self, from: data)
        }
        set {
            if let newValue = newValue, let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.currentLevel)
            } else {
                defaults.removeObject(forKey: Keys.currentLevel)
            }
        }
    }

    var isIntroCompleted: Bool {
        get { defaults.bool(forKey: Keys.isIntroCompleted) }
        set { defaults.set(newValue, forKey: Keys.isIntroCompleted) }
    }

    var maxLives: Int {
        get { defaults.integer(forKey: Keys.maxLives).nonZeroOr(5) }
        set { defaults.set(newValue, forKey: Keys.maxLives) }
    }

    var currentLives: Int {
        get { defaults.integer(forKey: Keys.currentLives).nonZeroOr(5) }
        set { defaults.set(newValue, forKey: Keys.currentLives) }
    }

    // MARK: - Initialization

    private init() {
        self.defaults = UserDefaults.standard
        levelNumber = defaults.integer(forKey: Keys.levelNumber).nonZeroOr(1)
        theme = AppTheme(rawValue: defaults.string(forKey: Keys.theme) ?? "") ?? .dark
        animationSpeed = AnimationSpeed(rawValue: defaults.string(forKey: Keys.animationSpeed) ?? "") ?? .medium
        isVibrationEnabled = defaults.object(forKey: Keys.isVibrationEnabled) as? Bool ?? true
        isSoundsEnabled = defaults.object(forKey: Keys.isSoundsEnabled) as? Bool ?? true
        isFillBoardEnabled = defaults.object(forKey: Keys.isFillBoardEnabled) as? Bool ?? false
        isWinVideosEnabled = defaults.object(forKey: Keys.isWinVideosEnabled) as? Bool ?? false
        arrowThickness = ArrowThickness(rawValue: defaults.string(forKey: Keys.arrowThickness) ?? "") ?? .medium
        isAdFree = defaults.object(forKey: Keys.isAdFree) as? Bool ?? false
        rewardAdCount = defaults.integer(forKey: Keys.rewardAdCount)
    }

    /// Initializer for isolated test instances using a named suite.
    init(suiteName: String) {
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
        levelNumber = defaults.integer(forKey: Keys.levelNumber).nonZeroOr(1)
        theme = AppTheme(rawValue: defaults.string(forKey: Keys.theme) ?? "") ?? .dark
        animationSpeed = AnimationSpeed(rawValue: defaults.string(forKey: Keys.animationSpeed) ?? "") ?? .medium
        isVibrationEnabled = defaults.object(forKey: Keys.isVibrationEnabled) as? Bool ?? true
        isSoundsEnabled = defaults.object(forKey: Keys.isSoundsEnabled) as? Bool ?? true
        isFillBoardEnabled = defaults.object(forKey: Keys.isFillBoardEnabled) as? Bool ?? false
        isWinVideosEnabled = defaults.object(forKey: Keys.isWinVideosEnabled) as? Bool ?? false
        arrowThickness = ArrowThickness(rawValue: defaults.string(forKey: Keys.arrowThickness) ?? "") ?? .medium
        isAdFree = defaults.object(forKey: Keys.isAdFree) as? Bool ?? false
        rewardAdCount = defaults.integer(forKey: Keys.rewardAdCount)
    }

    // MARK: - Transient State (not persisted)
    var pendingCustomGame: CustomGameConfig?

    // MARK: - Methods
    func clearSavedGame() {
        defaults.removeObject(forKey: Keys.initialLevel)
        defaults.removeObject(forKey: Keys.currentLevel)
    }

    func resetProgress() {
        levelNumber = 1
        clearSavedGame()
    }
}

// MARK: - Helper Extension
private extension Int {
    func nonZeroOr(_ defaultValue: Int) -> Int {
        self == 0 ? defaultValue : self
    }
}
