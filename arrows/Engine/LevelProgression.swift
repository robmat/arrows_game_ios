//
//  LevelProgression.swift
//  arrows
//
//  Calculates level difficulty progression
//

import Foundation

enum LevelProgression {
    private static let baseBoardSize = 5
    private static let sizeReductionPerStep = 3
    private static let livesReductionPerStep = 1
    private static let levelsPerProgressionStep = 10
    private static let defaultInitialLives = 5
    private static let minSnakeLengthBase = 3
    private static let minSnakeLengthMin = 4
    private static let minSnakeLengthMax = 30

    static func calculateLevelConfiguration(
        levelNum: Int,
        forcedWidth: Int? = nil,
        forcedHeight: Int? = nil,
        forcedLives: Int? = nil
    ) -> LevelConfiguration {
        let progressionStep = levelNum / levelsPerProgressionStep
        let sizeReduction = progressionStep * sizeReductionPerStep
        let livesReduction = progressionStep * livesReductionPerStep

        let baseH = baseBoardSize + (levelNum - 1) / 2
        let baseW = baseBoardSize + levelNum / 2

        let h = forcedHeight ?? max(1, baseH - sizeReduction)
        let w = forcedWidth ?? max(1, baseW - sizeReduction)

        let maxLives = forcedLives ?? max(1, defaultInitialLives - livesReduction)
        let snakeLen = min(max(minSnakeLengthBase + levelNum / 2, minSnakeLengthMin), minSnakeLengthMax)

        return LevelConfiguration(width: w, height: h, maxSnakeLength: snakeLen, maxLives: maxLives)
    }
}
