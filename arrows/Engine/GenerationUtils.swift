//
//  GenerationUtils.swift
//  arrows
//
//  Utility functions for level generation
//

import Foundation

enum GenerationUtils {
    static func isInside(_ p: Point, width w: Int, height h: Int) -> Bool {
        p.x >= 0 && p.x < w && p.y >= 0 && p.y < h
    }

    static func forbiddenPoints(head: Point, direction dir: Direction, width w: Int, height h: Int) -> Set<Point> {
        var points = Set<Point>()
        var current = head + dir
        while isInside(current, width: w, height: h) {
            points.insert(current)
            current = current + dir
        }
        return points
    }

    static func hasClearLoS(start: Point, direction dir: Direction, occupied: [[Bool]], width w: Int, height h: Int) -> Bool {
        var current = start + dir
        while isInside(current, width: w, height: h) {
            if occupied[current.x][current.y] { return false }
            current = current + dir
        }
        return true
    }

    static func countValidCells(width: Int, height: Int, walls: [[Bool]]) -> Int {
        var count = 0
        for x in 0..<width {
            for y in 0..<height {
                if !walls[x][y] { count += 1 }
            }
        }
        return count
    }

    static func isFreeAt(_ p: Point, occupied: [[Bool]], config: GameGeneratorConfig) -> Bool {
        isInside(p, width: config.width, height: config.height) &&
            !occupied[p.x][p.y] && !config.walls[p.x][p.y]
    }

    static func getOrderedDirections(
        possible: [Direction],
        prevDir: Direction?,
        straightPreference: Float
    ) -> [Direction] {
        guard let prevDir = prevDir, straightPreference > 0 else { return possible }
        let shouldGoStraight = possible.contains(prevDir) && Float.random(in: 0...1) < straightPreference
        if shouldGoStraight {
            return [prevDir] + possible.filter { $0 != prevDir }
        }
        return possible
    }
}
