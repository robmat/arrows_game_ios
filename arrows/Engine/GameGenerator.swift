//
//  GameGenerator.swift
//  arrows
//
//  Generates solvable puzzle levels
//

import Foundation

class GameGenerator {
    private var straightPreference: Float = GameConstants.defaultStraightPreference
    private var snakeBuilder: SnakeBuilder

    init() {
        snakeBuilder = SnakeBuilder(straightPreference: straightPreference)
    }

    func setStraightPreference(_ value: Float) {
        precondition(value >= 0 && value <= 1, "straightPreference must be in [0, 1]")
        straightPreference = value
        snakeBuilder = SnakeBuilder(straightPreference: value)
    }

    func generateSolvableLevel(params: GenerationParams) -> GameLevel {
        let width = params.fillTheBoard ? min(params.width, GameConstants.maxFillBoardSize) : params.width
        let height = params.fillTheBoard ? min(params.height, GameConstants.maxFillBoardSize) : params.height

        let walls = params.boardShape?.getWalls(width: width, height: height) ??
            Array(repeating: Array(repeating: false, count: height), count: width)

        let config = GameGeneratorConfig(
            width: width,
            height: height,
            maxSnakeLength: params.maxSnakeLength,
            fillTheBoard: params.fillTheBoard,
            walls: walls
        )

        var context = GenerationContext(
            config: config,
            occupied: Array(repeating: Array(repeating: false, count: height), count: width),
            snakes: [],
            frontierCandidates: []
        )

        let totalCells = GenerationUtils.countValidCells(width: width, height: height, walls: walls)
        generateInitialSnakes(context: &context, totalCells: totalCells, onProgress: params.onProgress)

        if params.fillTheBoard {
            fillRemainingBoard(context: &context, totalCells: totalCells, onProgress: params.onProgress)
        }

        return GameLevel(width: width, height: height, snakes: context.snakes)
    }

    private func generateInitialSnakes(context: inout GenerationContext, totalCells: Int, onProgress: (Float) -> Void) {
        guard var snake = snakeBuilder.buildFirstSnake(config: context.config, occupied: context.occupied) else {
            return
        }

        while true {
            addSnakeToContext(context: &context, snake: snake)
            onProgress(calculateProgress(snakes: context.snakes, totalCells: totalCells))

            guard let nextSnake = snakeBuilder.buildNextSnake(context: &context) else {
                break
            }
            snake = nextSnake
        }
    }

    private func addSnakeToContext(context: inout GenerationContext, snake: Snake) {
        context.snakes.append(snake)

        // Mark occupied cells
        for point in snake.body {
            context.occupied[point.x][point.y] = true
        }

        // Remove candidates that are now occupied
        for point in snake.body {
            for dir in Direction.allCases {
                context.frontierCandidates.remove(FrontierCandidate(point: point, direction: dir))
            }
        }

        // Add new frontier candidates
        updateFrontierWithSnake(context: &context, snake: snake)
    }

    private func updateFrontierWithSnake(context: inout GenerationContext, snake: Snake) {
        for segment in snake.body {
            for dir in Direction.allCases {
                let neighbor = segment + dir
                if isFreeAt(neighbor, context: context) {
                    addFrontierCandidatesForPoint(context: &context, point: neighbor)
                }
            }
        }
    }

    private func addFrontierCandidatesForPoint(context: inout GenerationContext, point p: Point) {
        for headDir in Direction.allCases {
            let hasLoS = GenerationUtils.hasClearLoS(
                start: p,
                direction: headDir,
                occupied: context.occupied,
                width: context.config.width,
                height: context.config.height
            )
            if hasLoS {
                context.frontierCandidates.insert(FrontierCandidate(point: p, direction: headDir))
            }
        }
    }

    private func fillRemainingBoard(context: inout GenerationContext, totalCells: Int, onProgress: (Float) -> Void) {
        while let lastSnake = snakeBuilder.buildLastSnake(context: context) {
            context.snakes.append(lastSnake)
            onProgress(calculateProgress(snakes: context.snakes, totalCells: totalCells))
            for point in lastSnake.body {
                context.occupied[point.x][point.y] = true
            }
        }
    }

    private func isFreeAt(_ p: Point, context: GenerationContext) -> Bool {
        GenerationUtils.isInside(p, width: context.config.width, height: context.config.height) &&
            !context.occupied[p.x][p.y] && !context.config.walls[p.x][p.y]
    }

    private func calculateProgress(snakes: [Snake], totalCells: Int) -> Float {
        let occupiedCells = snakes.reduce(0) { $0 + $1.body.count }
        return min(Float(occupiedCells) / Float(totalCells), 1.0)
    }
}
