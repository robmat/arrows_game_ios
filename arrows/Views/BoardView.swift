//
//  BoardView.swift
//  arrows
//
//  Game board rendering with Canvas
//

import SwiftUI

extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        if self < range.lowerBound { return range.lowerBound }
        if self > range.upperBound { return range.upperBound }
        return self
    }
}

struct BoardView: View {
    @EnvironmentObject var preferences: UserPreferences
    @ObservedObject var engine: GameEngine
    var guidanceAlpha: CGFloat = 0
    @State private var flashPhase: CGFloat = 1.0
    @State private var flashTimer: Timer?

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            Canvas { context, canvasSize in
                drawBoard(context: context, size: canvasSize)
            }
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        engine.onTransform(translation: .zero, scale: value)
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        engine.onTransform(translation: value.translation, scale: 1.0)
                    }
            )
            .contentShape(Rectangle())
            .onTapGesture { location in
                engine.onTap(at: location, containerSize: size)
            }
            .scaleEffect(engine.scale)
            .offset(x: engine.offsetX, y: engine.offsetY)
        }
        .onAppear { startFlashTimer() }
        .onDisappear { flashTimer?.invalidate() }
    }

    private func startFlashTimer() {
        var goingDown = true
        let step = CGFloat((1.0 - GameConstants.flashMinAlpha) / (GameConstants.flashPulseDuration / 0.016))
        flashTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            if goingDown {
                flashPhase -= step
                if flashPhase <= GameConstants.flashMinAlpha {
                    flashPhase = GameConstants.flashMinAlpha
                    goingDown = false
                }
            } else {
                flashPhase += step
                if flashPhase >= 1.0 {
                    flashPhase = 1.0
                    goingDown = true
                }
            }
        }
    }

    private func drawBoard(context: GraphicsContext, size: CGSize) {
        let level = engine.level
        // Reserve margin so arrows on edge cells aren't clipped
        let margin = min(size.width, size.height) * 0.05
        let availableWidth = size.width - margin * 2
        let availableHeight = size.height - margin * 2
        let cellSize = min(availableWidth / CGFloat(level.width), availableHeight / CGFloat(level.height))
        let boardWidth = cellSize * CGFloat(level.width)
        let boardHeight = cellSize * CGFloat(level.height)
        let offsetX = (size.width - boardWidth) / 2
        let offsetY = (size.height - boardHeight) / 2

        let colors = preferences.theme.colors

        // Draw guidance lines
        if guidanceAlpha > 0 {
            drawGuidanceLines(
                context: context,
                level: level,
                cellSize: cellSize,
                offsetX: offsetX,
                offsetY: offsetY,
                canvasSize: size,
                accentColor: colors.accent
            )
        }

        // Draw each snake
        for snake in level.snakes {
            let isFlashing = engine.flashingSnakeId == snake.id
            let removalProgress = engine.removalProgress[snake.id]

            drawSnake(
                context: context,
                snake: snake,
                cellSize: cellSize,
                offsetX: offsetX,
                offsetY: offsetY,
                snakeColor: colors.snake,
                isFlashing: isFlashing,
                removalProgress: removalProgress
            )
        }
    }

    private func drawGuidanceLines(
        context: GraphicsContext,
        level: GameLevel,
        cellSize: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat,
        canvasSize: CGSize,
        accentColor: Color
    ) {
        for snake in level.snakes {
            // Skip snakes being removed
            if engine.removalProgress[snake.id] != nil { continue }

            let head = snake.body[0]
            let headCx = offsetX + CGFloat(head.x) * cellSize + cellSize / 2
            let headCy = offsetY + CGFloat(head.y) * cellSize + cellSize / 2

            // Calculate arrow tip position (same math as drawSnake + drawArrowHead)
            let cornerRadius = cellSize * GameConstants.arrowHeadOffset
            let arrowHeadSize = cellSize * GameConstants.arrowHeadLength
            let dx = CGFloat(snake.headDirection.dx)
            let dy = CGFloat(snake.headDirection.dy)
            let lineEndX = headCx + dx * cornerRadius
            let lineEndY = headCy + dy * cornerRadius
            let triangleCenterX = lineEndX + dx * (arrowHeadSize * 0.5)
            let triangleCenterY = lineEndY + dy * (arrowHeadSize * 0.5)
            let tipX = triangleCenterX + dx * arrowHeadSize
            let tipY = triangleCenterY + dy * arrowHeadSize

            // Calculate full end point (edge of canvas)
            let fullEnd: CGPoint
            switch snake.headDirection {
            case .up:
                fullEnd = CGPoint(x: tipX, y: 0)
            case .down:
                fullEnd = CGPoint(x: tipX, y: canvasSize.height)
            case .left:
                fullEnd = CGPoint(x: 0, y: tipY)
            case .right:
                fullEnd = CGPoint(x: canvasSize.width, y: tipY)
            }

            // Animate end point based on guidanceAlpha
            let endPoint = CGPoint(
                x: tipX + (fullEnd.x - tipX) * guidanceAlpha,
                y: tipY + (fullEnd.y - tipY) * guidanceAlpha
            )

            let alpha = GameConstants.guidanceLineAlphaFactor * guidanceAlpha

            var path = Path()
            path.move(to: CGPoint(x: tipX, y: tipY))
            path.addLine(to: endPoint)

            context.stroke(
                path,
                with: .color(accentColor.opacity(alpha)),
                style: StrokeStyle(
                    lineWidth: 2,
                    lineCap: .round,
                    dash: [GameConstants.guidanceDashOn, GameConstants.guidanceDashOff]
                )
            )
        }
    }

    private func drawSnake(
        context: GraphicsContext,
        snake: Snake,
        cellSize: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat,
        snakeColor: Color,
        isFlashing: Bool,
        removalProgress: Float?
    ) {
        guard !snake.body.isEmpty else { return }

        let strokeWidth = cellSize * preferences.arrowThickness.widthFactor
        let cornerRadius = cellSize * GameConstants.arrowHeadOffset

        // Progress p: 0 = normal, 1 = fully removed
        let p = CGFloat(removalProgress ?? 0)

        // Head slides out by shift amount — matches tail speed (tail travels (count-1)*cellSize)
        let bodyLength = CGFloat(max(snake.body.count - 1, 1))
        let shift = cellSize * bodyLength * p

        // Alpha fades from 1 to 0
        var alpha = 1.0 - p

        // Color and flashing
        var color = snakeColor
        if isFlashing {
            color = CommonColors.flashingRed
            alpha = alpha * flashPhase
        }

        // Original head position (without shift)
        let head = snake.body[0]
        let headCx0 = offsetX + CGFloat(head.x) * cellSize + cellSize / 2
        let headCy0 = offsetY + CGFloat(head.y) * cellSize + cellSize / 2

        // Shifted head position (slides out during removal)
        let headCx = headCx0 + CGFloat(snake.headDirection.dx) * shift
        let headCy = headCy0 + CGFloat(snake.headDirection.dy) * shift

        // Line end positions (where arrow head attaches)
        let lineEndX = headCx + CGFloat(snake.headDirection.dx) * cornerRadius
        let lineEndY = headCy + CGFloat(snake.headDirection.dy) * cornerRadius

        // Base line end (original position, used for curve end point)
        let baseLineEndX0 = headCx0 + CGFloat(snake.headDirection.dx) * cornerRadius
        let baseLineEndY0 = headCy0 + CGFloat(snake.headDirection.dy) * cornerRadius

        let snakeColor = color.opacity(alpha)

        if snake.body.count > 1 {
            // Multi-cell snake
            drawSnakeBody(
                context: context,
                snake: snake,
                cellSize: cellSize,
                offsetX: offsetX,
                offsetY: offsetY,
                cornerRadius: cornerRadius,
                strokeWidth: strokeWidth,
                p: p,
                headCx0: headCx0,
                headCy0: headCy0,
                baseLineEndX0: baseLineEndX0,
                baseLineEndY0: baseLineEndY0,
                lineEndX: lineEndX,
                lineEndY: lineEndY,
                color: snakeColor
            )
        } else {
            // Single cell snake - draw short tail
            let tailLength = cellSize * 0.2
            let tailStartX = lineEndX - CGFloat(snake.headDirection.dx) * (tailLength + cornerRadius)
            let tailStartY = lineEndY - CGFloat(snake.headDirection.dy) * (tailLength + cornerRadius)

            var path = Path()
            path.move(to: CGPoint(x: tailStartX, y: tailStartY))
            path.addLine(to: CGPoint(x: lineEndX, y: lineEndY))

            context.stroke(
                path,
                with: .color(snakeColor),
                style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
            )
        }

        // Draw arrow head at shifted position
        let headScale = preferences.arrowThickness.headScaleFactor
        let arrowHeadSize = cellSize * GameConstants.arrowHeadLength * headScale
        let triangleCenterX = lineEndX + CGFloat(snake.headDirection.dx) * (arrowHeadSize * 0.5)
        let triangleCenterY = lineEndY + CGFloat(snake.headDirection.dy) * (arrowHeadSize * 0.5)

        drawArrowHead(
            context: context,
            at: CGPoint(x: triangleCenterX, y: triangleCenterY),
            direction: snake.headDirection,
            cellSize: cellSize,
            color: snakeColor
        )
    }

    private func drawSnakeBody(
        context: GraphicsContext,
        snake: Snake,
        cellSize: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat,
        cornerRadius: CGFloat,
        strokeWidth: CGFloat,
        p: CGFloat,
        headCx0: CGFloat,
        headCy0: CGFloat,
        baseLineEndX0: CGFloat,
        baseLineEndY0: CGFloat,
        lineEndX: CGFloat,
        lineEndY: CGFloat,
        color: Color
    ) {
        let body = snake.body

        // Helper to get cell screen position
        func cellPos(_ i: Int) -> CGPoint {
            let cell = body[i]
            return CGPoint(
                x: offsetX + CGFloat(cell.x) * cellSize + cellSize / 2,
                y: offsetY + CGFloat(cell.y) * cellSize + cellSize / 2
            )
        }

        // Check if there's a curve at a cell (direction change)
        func hasCurve(at i: Int) -> Bool {
            guard i > 0 && i < body.count - 1 else { return false }
            let prev = body[i + 1]
            let curr = body[i]
            let next = body[i - 1]
            // Curve exists if incoming and outgoing directions are not opposite
            return !((prev.x - curr.x == curr.x - next.x) && (prev.y - curr.y == curr.y - next.y))
        }

        // Calculate exact tail position as float index
        let tailPosition = CGFloat(body.count - 1) * (1.0 - p)
        let cellIndex = Int(tailPosition)
        let fraction = tailPosition - CGFloat(cellIndex)

        let fromIndex = min(cellIndex, body.count - 1)
        let toIndex = min(cellIndex + 1, body.count - 1)

        var path = Path()

        // Handle start position - check if we're on a curve
        let hasPartialCurve = fraction > 0.001 && toIndex != fromIndex && hasCurve(at: fromIndex)

        if hasPartialCurve && fromIndex > 0 && fromIndex < body.count - 1 {
            // Starting in the middle of a curve - calculate point on curve
            let prev = body[fromIndex + 1]
            let curr = body[fromIndex]
            let next = body[fromIndex - 1]

            let center = cellPos(fromIndex)
            let entry = CGPoint(
                x: center.x + CGFloat((prev.x - curr.x).clamped(to: -1...1)) * cornerRadius,
                y: center.y + CGFloat((prev.y - curr.y).clamped(to: -1...1)) * cornerRadius
            )
            let exit = CGPoint(
                x: center.x + CGFloat((next.x - curr.x).clamped(to: -1...1)) * cornerRadius,
                y: center.y + CGFloat((next.y - curr.y).clamped(to: -1...1)) * cornerRadius
            )

            // t parameter: 0 = entry, 1 = exit
            // fraction represents how far we are towards toIndex (tail direction)
            // So we want to start at t = (1 - fraction) on the curve
            let t = 1.0 - fraction

            // Quadratic Bezier point at parameter t
            let mt = 1.0 - t
            let startPoint = CGPoint(
                x: mt * mt * entry.x + 2 * mt * t * center.x + t * t * exit.x,
                y: mt * mt * entry.y + 2 * mt * t * center.y + t * t * exit.y
            )

            path.move(to: startPoint)

            // Draw remaining part of curve using de Casteljau subdivision
            // New control point for curve from t to 1: lerp(center, exit, t)
            let partialControl = CGPoint(
                x: center.x + t * (exit.x - center.x),
                y: center.y + t * (exit.y - center.y)
            )
            path.addQuadCurve(to: exit, control: partialControl)
        } else if fraction > 0.001 && toIndex != fromIndex {
            // Starting on a straight segment - interpolate linearly
            let from = cellPos(fromIndex)
            let to = cellPos(toIndex)
            let startPoint = CGPoint(
                x: from.x + fraction * (to.x - from.x),
                y: from.y + fraction * (to.y - from.y)
            )
            path.move(to: startPoint)
        } else {
            // At a cell center
            path.move(to: cellPos(fromIndex))
        }

        // Draw curves for middle segments (from fromIndex-1 down to 1)
        // Skip fromIndex since we already handled it above (partial or not)
        for i in stride(from: fromIndex - 1, through: 1, by: -1) {
            let prev = body[i + 1]
            let current = body[i]
            let next = body[i - 1]

            let currX = offsetX + CGFloat(current.x) * cellSize + cellSize / 2
            let currY = offsetY + CGFloat(current.y) * cellSize + cellSize / 2

            let entryX = currX + CGFloat((prev.x - current.x).clamped(to: -1...1)) * cornerRadius
            let entryY = currY + CGFloat((prev.y - current.y).clamped(to: -1...1)) * cornerRadius

            let exitX = currX + CGFloat((next.x - current.x).clamped(to: -1...1)) * cornerRadius
            let exitY = currY + CGFloat((next.y - current.y).clamped(to: -1...1)) * cornerRadius

            path.addLine(to: CGPoint(x: entryX, y: entryY))
            path.addQuadCurve(to: CGPoint(x: exitX, y: exitY), control: CGPoint(x: currX, y: currY))
        }

        // Draw head segment curve
        if fromIndex >= 1 {
            // Full head curve
            let prev = body[1]
            let headEntryX = headCx0 + CGFloat((prev.x - body[0].x).clamped(to: -1...1)) * cornerRadius
            let headEntryY = headCy0 + CGFloat((prev.y - body[0].y).clamped(to: -1...1)) * cornerRadius

            path.addLine(to: CGPoint(x: headEntryX, y: headEntryY))
            path.addQuadCurve(
                to: CGPoint(x: baseLineEndX0, y: baseLineEndY0),
                control: CGPoint(x: headCx0, y: headCy0)
            )
        } else if fromIndex == 0 && fraction > 0.001 && body.count > 1 {
            // Partial head curve - we're in the middle of removing the head segment
            let prev = body[1]
            let headEntry = CGPoint(
                x: headCx0 + CGFloat((prev.x - body[0].x).clamped(to: -1...1)) * cornerRadius,
                y: headCy0 + CGFloat((prev.y - body[0].y).clamped(to: -1...1)) * cornerRadius
            )
            let headCenter = CGPoint(x: headCx0, y: headCy0)
            let headExit = CGPoint(x: baseLineEndX0, y: baseLineEndY0)

            // t parameter: fraction represents how far we are towards cell 1 (away from head)
            // So we want to start at t = (1 - fraction) on the head curve
            let t = 1.0 - fraction

            // Quadratic Bezier point at parameter t
            let mt = 1.0 - t
            let startPoint = CGPoint(
                x: mt * mt * headEntry.x + 2 * mt * t * headCenter.x + t * t * headExit.x,
                y: mt * mt * headEntry.y + 2 * mt * t * headCenter.y + t * t * headExit.y
            )

            path.move(to: startPoint)

            // Draw remaining part of head curve using de Casteljau subdivision
            let partialControl = CGPoint(
                x: headCenter.x + t * (headExit.x - headCenter.x),
                y: headCenter.y + t * (headExit.y - headCenter.y)
            )
            path.addQuadCurve(to: headExit, control: partialControl)
        }

        // If removing, extend line to shifted head position
        if p > 0 {
            path.addLine(to: CGPoint(x: lineEndX, y: lineEndY))
        }

        context.stroke(
            path,
            with: .color(color),
            style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
        )
    }

    private func directionFrom(_ from: Point, to: Point) -> Direction {
        let dx = to.x - from.x
        let dy = to.y - from.y

        if dx > 0 { return .right }
        if dx < 0 { return .left }
        if dy > 0 { return .down }
        return .up
    }

    private func drawArrowHead(
        context: GraphicsContext,
        at center: CGPoint,
        direction: Direction,
        cellSize: CGFloat,
        color: Color
    ) {
        let headScale = preferences.arrowThickness.headScaleFactor
        let arrowLength = cellSize * GameConstants.arrowHeadLength * headScale
        let arrowWidth = cellSize * GameConstants.arrowHeadWidth * headScale
        let angle: Double

        switch direction {
        case .up: angle = GameConstants.angleUp
        case .down: angle = GameConstants.angleDown
        case .left: angle = GameConstants.angleLeft
        case .right: angle = GameConstants.angleRight
        }

        let angleRad = angle * .pi / 180

        // Tip of the arrow
        let tip = CGPoint(
            x: center.x + arrowLength * CGFloat(cos(angleRad)),
            y: center.y + arrowLength * CGFloat(sin(angleRad))
        )

        // Base points of the triangle (perpendicular to direction)
        let perpAngle = angleRad + .pi / 2
        let baseCenter = CGPoint(
            x: center.x - arrowLength * 0.3 * CGFloat(cos(angleRad)),
            y: center.y - arrowLength * 0.3 * CGFloat(sin(angleRad))
        )
        let point2 = CGPoint(
            x: baseCenter.x + arrowWidth * CGFloat(cos(perpAngle)),
            y: baseCenter.y + arrowWidth * CGFloat(sin(perpAngle))
        )
        let point3 = CGPoint(
            x: baseCenter.x - arrowWidth * CGFloat(cos(perpAngle)),
            y: baseCenter.y - arrowWidth * CGFloat(sin(perpAngle))
        )

        var path = Path()
        path.move(to: tip)
        path.addLine(to: point2)
        path.addLine(to: point3)
        path.closeSubpath()

        context.fill(path, with: .color(color))
    }
}

#Preview {
    let engine = GameEngine()
    return BoardView(engine: engine)
        .environmentObject(UserPreferences.shared)
        .frame(width: 300, height: 300)
        .background(Color(hex: 0x1E1F28))
}
