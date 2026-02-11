//
//  GameModels.swift
//  arrows
//
//  Core game data structures
//

import Foundation

struct Point: Equatable, Hashable, Codable {
    let x: Int
    let y: Int

    static func + (lhs: Point, rhs: Direction) -> Point {
        Point(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }
}

enum Direction: String, CaseIterable, Codable {
    case up, down, left, right

    var dx: Int {
        switch self {
        case .up, .down: return 0
        case .left: return -1
        case .right: return 1
        }
    }

    var dy: Int {
        switch self {
        case .up: return -1
        case .down: return 1
        case .left, .right: return 0
        }
    }

    var opposite: Direction {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }
}

struct Snake: Identifiable, Equatable, Codable {
    let id: Int
    let body: [Point] // Ordered list: Head -> ... -> Tail
    let headDirection: Direction

    var head: Point { body.first! }

    static func == (lhs: Snake, rhs: Snake) -> Bool {
        lhs.id == rhs.id
    }
}

struct GameLevel: Equatable, Codable {
    let width: Int
    let height: Int
    var snakes: [Snake]

    func removingSnake(id: Int) -> GameLevel {
        GameLevel(width: width, height: height, snakes: snakes.filter { $0.id != id })
    }
}

struct LevelConfiguration {
    let width: Int
    let height: Int
    let maxSnakeLength: Int
    let maxLives: Int
}
