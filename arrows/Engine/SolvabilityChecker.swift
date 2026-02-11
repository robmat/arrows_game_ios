//
//  SolvabilityChecker.swift
//  arrows
//
//  Verifies that generated levels are solvable
//

import Foundation

enum SolvabilityChecker {
    private static let solvabilityIterationMargin = 10

    static func isResolvable(_ level: GameLevel) -> Bool {
        var grid = createGrid(level)
        let snakeMap = Dictionary(uniqueKeysWithValues: level.snakes.map { ($0.id, $0) })
        var remaining = Set(snakeMap.keys)
        let maxIter = level.snakes.count + solvabilityIterationMargin
        var iter = 0

        while !remaining.isEmpty && iter < maxIter {
            iter += 1
            guard let removable = remaining.first(where: { sId in
                guard let snake = snakeMap[sId] else { return false }
                return hasCleanLoS(
                    head: snake.head,
                    direction: snake.headDirection,
                    snakeId: sId,
                    grid: grid,
                    width: level.width,
                    height: level.height
                )
            }) else {
                return false
            }

            // Remove snake from grid
            if let snake = snakeMap[removable] {
                for point in snake.body {
                    grid[point.x][point.y] = 0
                }
            }
            remaining.remove(removable)
        }
        return remaining.isEmpty
    }

    static func findRemovableSnake(_ level: GameLevel) -> Int? {
        let grid = createGrid(level)
        return level.snakes.first { snake in
            hasCleanLoS(
                head: snake.head,
                direction: snake.headDirection,
                snakeId: snake.id,
                grid: grid,
                width: level.width,
                height: level.height
            )
        }?.id
    }

    static func isLineOfSightObstructed(_ level: GameLevel, snake: Snake, ignoreIds: Set<Int> = []) -> Bool {
        let head = snake.head
        let direction = snake.headDirection
        var current = head + direction

        while isInside(current, width: level.width, height: level.height) {
            let isOccupied = level.snakes.contains { other in
                !ignoreIds.contains(other.id) && other.body.contains(current)
            }
            if isOccupied { return true }
            current = current + direction
        }
        return false
    }

    private static func createGrid(_ level: GameLevel) -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: level.height), count: level.width)
        for snake in level.snakes {
            for point in snake.body {
                grid[point.x][point.y] = snake.id
            }
        }
        return grid
    }

    private static func hasCleanLoS(head: Point, direction dir: Direction, snakeId sId: Int, grid: [[Int]], width w: Int, height h: Int) -> Bool {
        var curr = head + dir
        while isInside(curr, width: w, height: h) {
            let cellValue = grid[curr.x][curr.y]
            if cellValue != 0 && cellValue != sId { return false }
            curr = curr + dir
        }
        return true
    }

    private static func isInside(_ p: Point, width w: Int, height h: Int) -> Bool {
        p.x >= 0 && p.x < w && p.y >= 0 && p.y < h
    }
}
