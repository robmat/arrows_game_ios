//
//  GameEngine.swift
//  arrows
//
//  Main game state controller
//

import Foundation
import Combine
import SwiftUI

@MainActor
class GameEngine: ObservableObject {
    // MARK: - Published State
    @Published var levelNumber: Int = 1
    @Published var level: GameLevel = GameLevel(width: 1, height: 1, snakes: [])
    @Published var isLoading: Bool = true
    @Published var totalSnakesInLevel: Int = 0
    @Published var isGameWon: Bool = false
    @Published var isGameOver: Bool = false
    @Published var loadingProgress: Float = 0
    @Published var lives: Int = 5
    @Published var maxLives: Int = 5

    @Published var scale: CGFloat = 1.0
    @Published var offsetX: CGFloat = 0
    @Published var offsetY: CGFloat = 0

    @Published var removalProgress: [Int: Float] = [:]
    @Published var flashingSnakeId: Int? = nil

    // MARK: - Private Properties
    private var initialLevel: GameLevel?
    private let gameGenerator = GameGenerator()
    private let preferences: UserPreferences
    private var cancellables = Set<AnyCancellable>()
    private var removalTasks: [Int: Task<Void, Never>] = [:]

    // MARK: - Settings
    var animationSpeed: AnimationSpeed {
        preferences.animationSpeed
    }

    var isVibrationEnabled: Bool {
        preferences.isVibrationEnabled
    }

    var isSoundsEnabled: Bool {
        preferences.isSoundsEnabled
    }

    // MARK: - Initialization
    init(preferences: UserPreferences? = nil) {
        self.preferences = preferences ?? UserPreferences.shared
        loadSavedState()
    }

    private func loadSavedState() {
        levelNumber = preferences.levelNumber

        if let savedLevel = preferences.currentLevel {
            initialLevel = preferences.initialLevel ?? savedLevel
            level = savedLevel
            totalSnakesInLevel = initialLevel?.snakes.count ?? savedLevel.snakes.count
            lives = preferences.currentLives
            maxLives = preferences.maxLives
            isGameWon = level.snakes.isEmpty
            isLoading = false
        } else {
            regenerateLevel()
        }
    }

    // MARK: - Public Methods

    func loadOrRegenerateLevel() {
        if initialLevel != nil {
            isLoading = false
        } else {
            regenerateLevel()
        }
    }

    func restartLevel() {
        guard let initial = initialLevel else { return }
        level = initial
        totalSnakesInLevel = initial.snakes.count
        isGameWon = false
        isGameOver = false
        lives = maxLives
        resetTransformation()
        clearFlash()
        clearRemovalProgress()
        saveState()
    }

    func showHint() {
        resetTransformation()
        if let removableId = SolvabilityChecker.findRemovableSnake(level) {
            flashSnake(id: removableId)
        }
    }

    func onTransform(translation: CGSize, scale: CGFloat) {
        self.scale = max(0.5, min(3.0, self.scale * scale))
        self.offsetX += translation.width
        self.offsetY += translation.height
    }

    func addLife() {
        if lives < maxLives {
            lives += 1
            saveState()
        }
    }

    func onTap(at point: CGPoint, containerSize: CGSize) {
        guard !isLoading && lives > 0 && !isGameWon && !isGameOver else { return }

        let gridCoords = transformTapToGrid(tapPoint: point, containerSize: containerSize)
        guard let tappedSnake = findTappedSnake(at: gridCoords) else { return }

        let isObstructed = SolvabilityChecker.isLineOfSightObstructed(
            level,
            snake: tappedSnake,
            ignoreIds: Set(removalProgress.keys)
        )

        handleSnakeTap(snake: tappedSnake, isObstructed: isObstructed)
    }

    func regenerateLevel() {
        isLoading = true
        loadingProgress = 0
        isGameWon = false
        isGameOver = false

        let config = LevelProgression.calculateLevelConfiguration(levelNum: levelNumber)
        let generator = self.gameGenerator

        Task.detached { [weak self] in
            let params = GenerationParams(
                width: config.width,
                height: config.height,
                maxSnakeLength: config.maxSnakeLength,
                fillTheBoard: false,
                onProgress: { progress in
                    Task { @MainActor in
                        self?.loadingProgress = progress
                    }
                }
            )

            let newLevel = generator.generateSolvableLevel(params: params)

            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.initialLevel = newLevel
                self.level = newLevel
                self.totalSnakesInLevel = newLevel.snakes.count
                self.maxLives = config.maxLives
                self.lives = config.maxLives
                self.resetTransformation()
                self.clearFlash()
                self.clearRemovalProgress()
                self.isLoading = false
                self.saveInitialState()
            }
        }
    }

    func nextLevel() {
        levelNumber += 1
        preferences.levelNumber = levelNumber
        preferences.clearSavedGame()
        initialLevel = nil
        regenerateLevel()
    }

    // MARK: - Private Methods

    private func transformTapToGrid(tapPoint: CGPoint, containerSize: CGSize) -> CGPoint {
        // tapPoint is already in Canvas local coordinates (SwiftUI handles the transform)
        // Just convert from Canvas coordinates to grid cell coordinates
        // Must match the margin used in BoardView.drawBoard
        let margin = min(containerSize.width, containerSize.height) * 0.05
        let availableWidth = containerSize.width - margin * 2
        let availableHeight = containerSize.height - margin * 2
        let cellSize = min(availableWidth / CGFloat(level.width), availableHeight / CGFloat(level.height))
        let boardWidth = cellSize * CGFloat(level.width)
        let boardHeight = cellSize * CGFloat(level.height)
        let leftOffset = (containerSize.width - boardWidth) / 2
        let topOffset = (containerSize.height - boardHeight) / 2

        let cellX = (tapPoint.x - leftOffset) / cellSize
        let cellY = (tapPoint.y - topOffset) / cellSize

        return CGPoint(x: cellX, y: cellY)
    }

    private func findTappedSnake(at gridCoords: CGPoint) -> Snake? {
        level.snakes
            .map { snake -> (Snake, CGFloat, Bool) in
                let head = snake.head
                let cellOffset = GameConstants.cellCenter + CGFloat(snake.headDirection.dx) * GameConstants.tapAreaOffsetFactor
                let tapAreaCenterX = CGFloat(head.x) + cellOffset
                let cellOffsetY = GameConstants.cellCenter + CGFloat(snake.headDirection.dy) * GameConstants.tapAreaOffsetFactor
                let tapAreaCenterY = CGFloat(head.y) + cellOffsetY

                let dx = tapAreaCenterX - gridCoords.x
                let dy = tapAreaCenterY - gridCoords.y
                let distSq = dx * dx + dy * dy

                let isObstructed = SolvabilityChecker.isLineOfSightObstructed(
                    level,
                    snake: snake,
                    ignoreIds: Set(removalProgress.keys)
                )

                return (snake, distSq, isObstructed)
            }
            .filter { $0.1 <= GameConstants.defaultTolerance * GameConstants.defaultTolerance }
            .min { lhs, rhs in
                if lhs.2 != rhs.2 { return !lhs.2 } // Prefer non-obstructed
                return lhs.1 < rhs.1
            }?.0
    }

    private func handleSnakeTap(snake: Snake, isObstructed: Bool) {
        if isObstructed {
            // Penalty
            if isVibrationEnabled {
                HapticManager.shared.error()
            }
            if isSoundsEnabled {
                SoundManager.shared.playPenalty()
            }
            flashSnake(id: snake.id)
            lives -= 1
            if lives <= 0 {
                isGameOver = true
                if isSoundsEnabled {
                    SoundManager.shared.playGameLost()
                }
            }
            saveState()
        } else {
            // Success
            if isVibrationEnabled {
                HapticManager.shared.success()
            }
            if !removalProgress.keys.contains(snake.id) {
                animateRemoval(snakeId: snake.id)
            }
        }
    }

    private func animateRemoval(snakeId: Int) {
        let duration: TimeInterval
        switch animationSpeed {
        case .high: duration = GameConstants.removalDurationHigh
        case .medium: duration = GameConstants.removalDurationMedium
        case .low: duration = GameConstants.removalDurationLow
        }

        removalProgress[snakeId] = 0

        let task = Task { @MainActor in
            let startTime = Date()
            while true {
                let elapsed = Date().timeIntervalSince(startTime)
                let progress = min(Float(elapsed / duration), 1.0)
                removalProgress[snakeId] = progress

                if progress >= 1.0 {
                    onSnakeRemoved(id: snakeId)
                    break
                }

                try? await Task.sleep(nanoseconds: UInt64(GameConstants.removalFrameDelay * 1_000_000_000))
            }
        }
        removalTasks[snakeId] = task
    }

    private func onSnakeRemoved(id: Int) {
        level = level.removingSnake(id: id)
        removalProgress.removeValue(forKey: id)
        removalTasks.removeValue(forKey: id)

        if level.snakes.isEmpty {
            isGameWon = true
            if isSoundsEnabled {
                SoundManager.shared.playGameWon()
            }
            preferences.clearSavedGame()
        } else {
            if isSoundsEnabled {
                SoundManager.shared.playSnakeRemoved()
            }
            saveState()
        }
    }

    private func flashSnake(id: Int) {
        flashingSnakeId = id
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(GameConstants.flashPulseDuration * 2 * 1_000_000_000))
            if flashingSnakeId == id {
                flashingSnakeId = nil
            }
        }
    }

    private func clearFlash() {
        flashingSnakeId = nil
    }

    private func clearRemovalProgress() {
        for task in removalTasks.values {
            task.cancel()
        }
        removalTasks.removeAll()
        removalProgress.removeAll()
    }

    private func resetTransformation() {
        scale = 1.0
        offsetX = 0
        offsetY = 0
    }

    private func saveState() {
        preferences.currentLevel = level
        preferences.currentLives = lives
    }

    private func saveInitialState() {
        preferences.initialLevel = initialLevel
        preferences.currentLevel = level
        preferences.maxLives = maxLives
        preferences.currentLives = lives
    }
}
