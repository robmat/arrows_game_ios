//
//  AppStrings.swift
//  arrows
//
//  Centralized localized strings for the app.
//  Organized by screen / feature using nested enums.
//

import Foundation

enum AppStrings {

    // MARK: - Main Menu

    enum MainMenu {
        static let title = String(localized: "Arrows")
        static let play = String(localized: "Play")
        static let generator = String(localized: "Generator")
        static let settings = String(localized: "Settings")

        static func levelNumber(_ n: Int) -> String {
            String(localized: "Level \(n)")
        }

        static func generatorLocked(_ level: Int) -> String {
            String(localized: "Generator (Level \(level))")
        }
    }

    // MARK: - Game

    enum Game {
        static let generatingLevel = String(localized: "Generating Level...")
        static let gameOver = String(localized: "Game Over")
        static let tryAgain = String(localized: "Try Again")
        static let mainMenu = String(localized: "Main Menu")
        static let loadingAd = String(localized: "Loading Ad...")
        static let adNotReady = String(localized: "Ad Not Ready")
        static let watchAdGetLife = String(localized: "Watch Ad → Get a Life")
        static let adBadge = String(localized: "Ad")

        static func levelNumber(_ n: Int) -> String {
            String(localized: "Level \(n)")
        }
    }

    // MARK: - Settings

    enum Settings {
        static let title = String(localized: "Settings")
        static let appearance = String(localized: "Appearance")
        static let theme = String(localized: "Theme")
        static let gameplay = String(localized: "Gameplay")
        static let animationSpeed = String(localized: "Animation Speed")
        static let arrowThickness = String(localized: "Arrow Thickness")
        static let vibration = String(localized: "Vibration")
        static let soundEffects = String(localized: "Sound Effects")
        static let winVideos = String(localized: "Win videos")
        static let fillBoard = String(localized: "Fill board (slower)")
        static let ads = String(localized: "Ads")
        static let removeAds = String(localized: "Remove Ads")
        static let removed = String(localized: "Removed")
        static let watchAd = String(localized: "Watch Ad")
        static let progress = String(localized: "Progress")
        static let currentLevel = String(localized: "Current Level")
        static let resetProgress = String(localized: "Reset Progress")
        static let cancel = String(localized: "Cancel")
        static let reset = String(localized: "Reset")
        static let resetConfirmationMessage = String(localized: "This will reset your progress to Level 1. Are you sure?")
        static let about = String(localized: "About")
        static let version = String(localized: "Version")
        static let versionNumber = String(localized: "1.1")
        static let basedOn = String(localized: "Based on")
        static let basedOnValue = String(localized: "Arrows Android")
        static let writeUs = String(localized: "Write Us")
    }

    // MARK: - Generator

    enum Generator {
        static let title = String(localized: "Generator")
        static let boardSize = String(localized: "Board Size")
        static let width = String(localized: "Width")
        static let height = String(localized: "Height")
        static let boardShape = String(localized: "Board Shape")
        static let rectangular = String(localized: "Rectangular")
        static let generateAndStart = String(localized: "Generate & Start")
        static let discardProgress = String(localized: "Discard Progress?")
        static let cancel = String(localized: "Cancel")
        static let proceed = String(localized: "Proceed")
        static let discardMessage = String(localized: "Starting a custom game will discard your currently saved game. Do you want to proceed?")
    }

    // MARK: - Win Celebration

    enum WinCelebration {
        static let continueButton = String(localized: "Continue")
        static let fallback = String(localized: "Well Done!")
    }

    // MARK: - Congratulations

    enum Congratulations {
        static let superb = String(localized: "Super!")
        static let fantastic = String(localized: "Fantastic!")
        static let great = String(localized: "Great!")
        static let goodJob = String(localized: "Good Job!")
        static let wellDone = String(localized: "Well Done!")
        static let awesome = String(localized: "Awesome!")
        static let excellent = String(localized: "Excellent!")
        static let amazing = String(localized: "Amazing!")
        static let brilliant = String(localized: "Brilliant!")
        static let outstanding = String(localized: "Outstanding!")

        static var all: [String] {
            [superb, fantastic, great, goodJob, wellDone, awesome, excellent, amazing, brilliant, outstanding]
        }
    }

    // MARK: - Shape Names

    enum ShapeName {
        static let bolt = String(localized: "Bolt")
        static let brick = String(localized: "Brick")
        static let build = String(localized: "Build")
        static let cannabis = String(localized: "Cannabis")
        static let queen = String(localized: "Queen")
        static let rook = String(localized: "Rook")
        static let delete = String(localized: "Delete")
        static let disabled = String(localized: "Disabled")
        static let favorite = String(localized: "Favorite")
        static let home = String(localized: "Home")
        static let humerus = String(localized: "Humerus")
        static let key = String(localized: "Key")
        static let starKid = String(localized: "Star Kid")
        static let moodBad = String(localized: "Mood Bad")
        static let satisfied = String(localized: "Satisfied")
        static let settings = String(localized: "Settings Shape", comment: "Display name for the Settings board shape")
        static let star = String(localized: "Star")
        static let tibia = String(localized: "Tibia")
        static let bottle = String(localized: "Bottle")
    }

    // MARK: - Animation Speed Names

    enum AnimationSpeedName {
        static let high = String(localized: "High")
        static let medium = String(localized: "Medium")
        static let low = String(localized: "Low")
    }

    // MARK: - Arrow Thickness Names

    enum ArrowThicknessName {
        static let thin = String(localized: "Thin")
        static let medium = String(localized: "Medium")
        static let thick = String(localized: "Thick")
    }

    // MARK: - Theme Names

    enum ThemeName {
        static let dark = String(localized: "Dark")
        static let green = String(localized: "Green")
        static let red = String(localized: "Red")
        static let yellow = String(localized: "Yellow")
        static let orange = String(localized: "Orange")
        static let blackAndWhite = String(localized: "Black & White")
    }
}
