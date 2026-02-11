//
//  SnakeBuilder.swift
//  arrows
//
//  Builds individual snakes for level generation
//

import Foundation

class SnakeBuilder {
    private var nextId: Int = 0
    private let straightPreference: Float

    init(straightPreference: Float = GameConstants.defaultStraightPreference) {
        self.straightPreference = straightPreference
    }

    private func getNextId() -> Int {
        nextId += 1
        return nextId
    }

    func buildFirstSnake(config: GameGeneratorConfig, occupied: [[Bool]]) -> Snake? {
        var head: Point
        var attempts = 0

        repeat {
            head = Point(x: Int.random(in: 0..<config.width), y: Int.random(in: 0..<config.height))
            attempts += 1
            if attempts > GameConstants.firstSnakeMaxAttempts { return nil }
        } while config.walls[head.x][head.y]

        let direction = Direction.allCases.randomElement()!
        let forbidden = GenerationUtils.forbiddenPoints(head: head, direction: direction, width: config.width, height: config.height)

        var params = SnakeRecursiveParams(
            config: config,
            occupied: occupied,
            snakes: [],
            body: [head],
            forbidden: forbidden,
            criterion: AlwaysTrueCriterion(),
            prevDir: nil
        )

        let body = buildSnakeRecursive(&params)
        return Snake(id: getNextId(), body: body, headDirection: direction)
    }

    func buildNextSnake(context: inout GenerationContext) -> Snake? {
        let candidates = Array(context.frontierCandidates).shuffled()
        var bestSnake: Snake? = nil

        for candidate in candidates {
            guard let snake = tryBuildNextSnake(context: context, head: candidate.point, direction: candidate.direction) else {
                continue
            }
            if snake.body.count >= context.config.maxSnakeLength { return snake }
            if bestSnake == nil || snake.body.count > bestSnake!.body.count {
                bestSnake = snake
            }
        }
        return bestSnake
    }

    private func tryBuildNextSnake(context: GenerationContext, head: Point, direction dir: Direction) -> Snake? {
        let isFree = GenerationUtils.isFreeAt(head, occupied: context.occupied, config: context.config)
        let hasLoS = isFree && GenerationUtils.hasClearLoS(
            start: head,
            direction: dir,
            occupied: context.occupied,
            width: context.config.width,
            height: context.config.height
        )

        guard hasLoS else { return nil }

        let forbidden = GenerationUtils.forbiddenPoints(head: head, direction: dir, width: context.config.width, height: context.config.height)

        var params = SnakeRecursiveParams(
            config: context.config,
            occupied: context.occupied,
            snakes: context.snakes,
            body: [head],
            forbidden: forbidden,
            criterion: NextToExistingSnakeCriterion(),
            prevDir: nil
        )

        let body = buildSnakeRecursive(&params)
        return Snake(id: getNextId(), body: body, headDirection: dir)
    }

    func buildLastSnake(context: GenerationContext) -> Snake? {
        let criterion = NextToExistingSnakeCriterion()
        let candidates = getFreeCandidates(context: context, criterion: criterion)

        // Try to find a snake that fills maxSnakeLength
        for (head, dir) in candidates where !context.config.walls[head.x][head.y] {
            if let snake = tryBuildBestSnake(context: context, head: head, direction: dir, criterion: criterion),
               snake.body.count >= context.config.maxSnakeLength {
                return snake
            }
        }

        // Find any resolvable snake
        return findAnyResolvableSnake(context: context, candidates: candidates, criterion: criterion)
    }

    private func getFreeCandidates(context: GenerationContext, criterion: Criterion) -> [(Point, Direction)] {
        var candidates: [(Point, Direction)] = []

        for x in 0..<context.config.width {
            for y in 0..<context.config.height {
                guard !context.occupied[x][y] else { continue }
                let point = Point(x: x, y: y)

                let params = CriterionParams(
                    body: [],
                    point: point,
                    snakes: context.snakes,
                    width: context.config.width,
                    height: context.config.height,
                    forbiddenPoints: [],
                    occupied: context.occupied
                )

                if criterion.isSatisfied(params: params) {
                    for dir in Direction.allCases {
                        candidates.append((point, dir))
                    }
                }
            }
        }
        return candidates.shuffled()
    }

    private func tryBuildBestSnake(context: GenerationContext, head: Point, direction dir: Direction, criterion: Criterion) -> Snake? {
        let forbidden = GenerationUtils.forbiddenPoints(head: head, direction: dir, width: context.config.width, height: context.config.height)

        var params = SnakeRecursiveParams(
            config: context.config,
            occupied: context.occupied,
            snakes: context.snakes,
            body: [head],
            forbidden: forbidden,
            criterion: criterion,
            prevDir: nil
        )

        let body = buildSnakeRecursive(&params)
        let snake = Snake(id: getNextId(), body: body, headDirection: dir)
        let level = GameLevel(width: context.config.width, height: context.config.height, snakes: context.snakes + [snake])

        return SolvabilityChecker.isResolvable(level) ? snake : nil
    }

    private func findAnyResolvableSnake(context: GenerationContext, candidates: [(Point, Direction)], criterion: Criterion) -> Snake? {
        var best: Snake? = nil

        for (head, dir) in candidates where !context.config.walls[head.x][head.y] {
            if let snake = tryBuildBestSnake(context: context, head: head, direction: dir, criterion: criterion) {
                if best == nil || snake.body.count > best!.body.count {
                    best = snake
                }
            }
        }
        return best
    }

    private func buildSnakeRecursive(_ params: inout SnakeRecursiveParams) -> [Point] {
        if params.body.count >= params.config.maxSnakeLength { return params.body }

        let tail = params.body.last!
        let possible = Direction.allCases.shuffled().filter { dir in
            canPlaceSegment(params: params, next: tail + dir)
        }

        if possible.isEmpty {
            return params.body
        }

        return findBestRecursiveSnake(&params, possible: possible)
    }

    private func findBestRecursiveSnake(_ params: inout SnakeRecursiveParams, possible: [Direction]) -> [Point] {
        let tail = params.body.last!
        let ordered = GenerationUtils.getOrderedDirections(
            possible: possible,
            prevDir: params.prevDir,
            straightPreference: straightPreference
        )

        var best = params.body

        for direction in ordered {
            var nextParams = params
            nextParams.body = params.body + [tail + direction]
            nextParams.prevDir = direction

            let candidate = buildSnakeRecursive(&nextParams)
            if candidate.count >= params.config.maxSnakeLength { return candidate }
            if candidate.count > best.count { best = candidate }
        }

        return best
    }

    private func canPlaceSegment(params: SnakeRecursiveParams, next: Point) -> Bool {
        guard GenerationUtils.isInside(next, width: params.config.width, height: params.config.height) else {
            return false
        }

        let isBasicFree = !params.forbidden.contains(next) &&
            !params.body.contains(next) &&
            !params.config.walls[next.x][next.y] &&
            !params.occupied[next.x][next.y]

        guard isBasicFree else { return false }

        let criterionParams = CriterionParams(
            body: params.body,
            point: next,
            snakes: params.snakes,
            width: params.config.width,
            height: params.config.height,
            forbiddenPoints: params.forbidden,
            occupied: params.occupied
        )

        return params.criterion.isSatisfied(params: criterionParams)
    }
}
