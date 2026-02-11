//
//  GameGeneratorModels.swift
//  arrows
//
//  Data models for level generation
//

import Foundation

struct GameGeneratorConfig {
    let width: Int
    let height: Int
    let maxSnakeLength: Int
    let fillTheBoard: Bool
    let walls: [[Bool]]
}

struct GenerationContext {
    let config: GameGeneratorConfig
    var occupied: [[Bool]]
    var snakes: [Snake]
    var frontierCandidates: Set<FrontierCandidate>
}

struct FrontierCandidate: Hashable {
    let point: Point
    let direction: Direction
}

struct GenerationParams {
    let width: Int
    let height: Int
    let maxSnakeLength: Int
    let fillTheBoard: Bool
    let boardShape: BoardShape?
    let onProgress: (Float) -> Void

    init(
        width: Int,
        height: Int,
        maxSnakeLength: Int,
        fillTheBoard: Bool = false,
        boardShape: BoardShape? = nil,
        onProgress: @escaping (Float) -> Void = { _ in }
    ) {
        self.width = width
        self.height = height
        self.maxSnakeLength = maxSnakeLength
        self.fillTheBoard = fillTheBoard
        self.boardShape = boardShape
        self.onProgress = onProgress
    }
}

protocol BoardShape {
    func getWalls(width: Int, height: Int) -> [[Bool]]
}

struct SnakeRecursiveParams {
    let config: GameGeneratorConfig
    let occupied: [[Bool]]
    let snakes: [Snake]
    var body: [Point]
    let forbidden: Set<Point>
    let criterion: Criterion
    var prevDir: Direction?
}

// MARK: - Criteria

protocol Criterion {
    func isSatisfied(params: CriterionParams) -> Bool
}

struct CriterionParams {
    let body: [Point]
    let point: Point
    let snakes: [Snake]
    let width: Int
    let height: Int
    let forbiddenPoints: Set<Point>
    let occupied: [[Bool]]
}

struct AlwaysTrueCriterion: Criterion {
    func isSatisfied(params: CriterionParams) -> Bool { true }
}

struct NextToExistingSnakeCriterion: Criterion {
    private let allDirections: [(Int, Int)] = [
        (-1, -1), (0, -1), (1, -1), (-1, 0),
        (1, 0), (-1, 1), (0, 1), (1, 1)
    ]

    func isSatisfied(params: CriterionParams) -> Bool {
        // Check if adjacent to any occupied cell
        for (dx, dy) in allDirections {
            let nx = params.point.x + dx
            let ny = params.point.y + dy
            if nx >= 0 && nx < params.width && ny >= 0 && ny < params.height && params.occupied[nx][ny] {
                return true
            }
        }

        // Check if adjacent to any segment of the snake body (excluding last)
        let bodyWithoutLast = params.body.count > 1 ? Array(params.body.dropLast()) : []
        return bodyWithoutLast.contains { segment in
            allDirections.contains { dx, dy in
                params.point.x + dx == segment.x && params.point.y + dy == segment.y
            }
        }
    }
}
