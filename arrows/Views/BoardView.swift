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
    @State private var flashPhase: CGFloat = 1.0

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
        .aspectRatio(CGFloat(engine.level.width) / CGFloat(engine.level.height), contentMode: .fit)
        .onAppear {
            startFlashAnimation()
        }
    }

    private func startFlashAnimation() {
        withAnimation(
            Animation.easeInOut(duration: GameConstants.flashPulseDuration)
                .repeatForever(autoreverses: true)
        ) {
            flashPhase = GameConstants.flashMinAlpha
        }
    }

    private func drawBoard(context: GraphicsContext, size: CGSize) {
        let level = engine.level
        let cellSize = min(size.width / CGFloat(level.width), size.height / CGFloat(level.height))
        let boardWidth = cellSize * CGFloat(level.width)
        let boardHeight = cellSize * CGFloat(level.height)
        let offsetX = (size.width - boardWidth) / 2
        let offsetY = (size.height - boardHeight) / 2

        let colors = preferences.theme.colors

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

        let strokeWidth = cellSize * GameConstants.snakeTailWidth
        let cornerRadius = cellSize * GameConstants.arrowHeadOffset

        // Progress p: 0 = normal, 1 = fully removed
        let p = CGFloat(removalProgress ?? 0)

        // Head slides out by shift amount
        let shift = cellSize * GameConstants.snakeMoveDistFactor * p

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
        let arrowHeadSize = cellSize * GameConstants.arrowHeadLength
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

        // Calculate exact tail position as float index (0 = head, body.count-1 = tail)
        // As p goes 0→1, tailPosition goes (body.count-1)→0
        let tailPosition = CGFloat(body.count - 1) * (1.0 - p)
        let cellIndex = Int(tailPosition)
        let fraction = tailPosition - CGFloat(cellIndex)

        // Clamp indices to valid range
        let fromIndex = min(cellIndex, body.count - 1)
        let toIndex = min(cellIndex + 1, body.count - 1)

        // Calculate interpolated start position
        let fromCell = body[fromIndex]
        let fromX = offsetX + CGFloat(fromCell.x) * cellSize + cellSize / 2
        let fromY = offsetY + CGFloat(fromCell.y) * cellSize + cellSize / 2

        var startX = fromX
        var startY = fromY

        if toIndex != fromIndex && fraction > 0.001 {
            let toCell = body[toIndex]
            let toX = offsetX + CGFloat(toCell.x) * cellSize + cellSize / 2
            let toY = offsetY + CGFloat(toCell.y) * cellSize + cellSize / 2
            // Interpolate from fromCell towards toCell
            startX = fromX + fraction * (toX - fromX)
            startY = fromY + fraction * (toY - fromY)
        }

        var path = Path()
        path.move(to: CGPoint(x: startX, y: startY))

        // Draw curves for middle segments (from fromIndex-1 down to 1)
        for i in stride(from: fromIndex - 1, through: 1, by: -1) {
            let prev = body[i + 1]
            let current = body[i]
            let next = body[i - 1]

            let currX = offsetX + CGFloat(current.x) * cellSize + cellSize / 2
            let currY = offsetY + CGFloat(current.y) * cellSize + cellSize / 2

            // Entry point (from previous cell direction)
            let entryX = currX + CGFloat((prev.x - current.x).clamped(to: -1...1)) * cornerRadius
            let entryY = currY + CGFloat((prev.y - current.y).clamped(to: -1...1)) * cornerRadius

            // Exit point (towards next cell direction)
            let exitX = currX + CGFloat((next.x - current.x).clamped(to: -1...1)) * cornerRadius
            let exitY = currY + CGFloat((next.y - current.y).clamped(to: -1...1)) * cornerRadius

            path.addLine(to: CGPoint(x: entryX, y: entryY))
            path.addQuadCurve(to: CGPoint(x: exitX, y: exitY), control: CGPoint(x: currX, y: currY))
        }

        // Draw head segment curve (only if we have more than 1 cell visible)
        if fromIndex >= 1 {
            let prev = body[1]
            let headEntryX = headCx0 + CGFloat((prev.x - body[0].x).clamped(to: -1...1)) * cornerRadius
            let headEntryY = headCy0 + CGFloat((prev.y - body[0].y).clamped(to: -1...1)) * cornerRadius

            path.addLine(to: CGPoint(x: headEntryX, y: headEntryY))
            path.addQuadCurve(
                to: CGPoint(x: baseLineEndX0, y: baseLineEndY0),
                control: CGPoint(x: headCx0, y: headCy0)
            )
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
        let arrowLength = cellSize * GameConstants.arrowHeadLength
        let arrowWidth = cellSize * GameConstants.arrowHeadWidth
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
