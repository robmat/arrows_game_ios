//
//  arrowsTests.swift
//  arrowsTests
//
//  Tests for the Arrows game engine
//

import Testing
@testable import arrows

struct GameEngineTests {

    @Test func testPointAddition() async throws {
        let point = Point(x: 5, y: 5)
        let moved = point + Direction.up
        #expect(moved.x == 5)
        #expect(moved.y == 4)
    }

    @Test func testDirectionValues() async throws {
        #expect(Direction.up.dy == -1)
        #expect(Direction.down.dy == 1)
        #expect(Direction.left.dx == -1)
        #expect(Direction.right.dx == 1)
    }

    @Test func testLevelProgression() async throws {
        let config1 = LevelProgression.calculateLevelConfiguration(levelNum: 1)
        #expect(config1.width >= 5)
        #expect(config1.height >= 5)
        #expect(config1.maxLives == 5)

        let config10 = LevelProgression.calculateLevelConfiguration(levelNum: 10)
        #expect(config10.width >= config1.width) // Board grows with level

        let config20 = LevelProgression.calculateLevelConfiguration(levelNum: 20)
        #expect(config20.maxLives < 5) // Lives decrease over time
    }

    @Test func testSolvabilityChecker() async throws {
        // Create a simple level with one snake that can be removed
        let snake = Snake(
            id: 1,
            body: [Point(x: 2, y: 2), Point(x: 3, y: 2), Point(x: 4, y: 2)],
            headDirection: .left
        )
        let level = GameLevel(width: 5, height: 5, snakes: [snake])

        let isResolvable = SolvabilityChecker.isResolvable(level)
        #expect(isResolvable == true)

        let removableId = SolvabilityChecker.findRemovableSnake(level)
        #expect(removableId == 1)
    }

    @Test func testSnakeLineOfSight() async throws {
        // Snake pointing left at x=2, nothing blocking
        let snake1 = Snake(
            id: 1,
            body: [Point(x: 2, y: 2), Point(x: 3, y: 2)],
            headDirection: .left
        )
        let level1 = GameLevel(width: 5, height: 5, snakes: [snake1])

        let obstructed1 = SolvabilityChecker.isLineOfSightObstructed(level1, snake: snake1)
        #expect(obstructed1 == false)

        // Snake pointing left at x=3, blocked by another snake at x=1
        let blockingSnake = Snake(
            id: 2,
            body: [Point(x: 1, y: 2)],
            headDirection: .down
        )
        let snake2 = Snake(
            id: 1,
            body: [Point(x: 3, y: 2), Point(x: 4, y: 2)],
            headDirection: .left
        )
        let level2 = GameLevel(width: 5, height: 5, snakes: [snake2, blockingSnake])

        let obstructed2 = SolvabilityChecker.isLineOfSightObstructed(level2, snake: snake2)
        #expect(obstructed2 == true)
    }

    @Test func testGameLevelRemoveSnake() async throws {
        let snake1 = Snake(id: 1, body: [Point(x: 0, y: 0)], headDirection: .right)
        let snake2 = Snake(id: 2, body: [Point(x: 1, y: 1)], headDirection: .down)
        let level = GameLevel(width: 5, height: 5, snakes: [snake1, snake2])

        let newLevel = level.removingSnake(id: 1)
        #expect(newLevel.snakes.count == 1)
        #expect(newLevel.snakes.first?.id == 2)
    }
}

struct GameGeneratorTests {

    @Test func testGenerateSolvableLevel() async throws {
        let generator = GameGenerator()
        let params = GenerationParams(
            width: 5,
            height: 5,
            maxSnakeLength: 10
        )

        let level = generator.generateSolvableLevel(params: params)

        #expect(level.width == 5)
        #expect(level.height == 5)
        #expect(level.snakes.count > 0)
        #expect(SolvabilityChecker.isResolvable(level))
    }
}
