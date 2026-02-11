//
//  BoardView.swift
//  arrows
//
//  Game board rendering with Canvas
//

import SwiftUI

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

        // Calculate color and alpha
        var color = snakeColor
        var alpha: CGFloat = 1.0

        if isFlashing {
            color = CommonColors.flashingRed
            alpha = flashPhase
        }

        if let progress = removalProgress {
            alpha = 1.0 - CGFloat(progress)
        }

        // Calculate movement offset for removal animation
        var moveOffsetX: CGFloat = 0
        var moveOffsetY: CGFloat = 0

        if let progress = removalProgress {
            let moveDist = cellSize * GameConstants.snakeMoveDistFactor * CGFloat(progress)
            moveOffsetX = CGFloat(snake.headDirection.dx) * moveDist
            moveOffsetY = CGFloat(snake.headDirection.dy) * moveDist
        }

        // Convert body points to screen coordinates (cell centers)
        let points = snake.body.map { point -> CGPoint in
            CGPoint(
                x: offsetX + CGFloat(point.x) * cellSize + cellSize / 2 + moveOffsetX,
                y: offsetY + CGFloat(point.y) * cellSize + cellSize / 2 + moveOffsetY
            )
        }

        let curveRadius = cellSize * GameConstants.arrowHeadOffset

        // Calculate where tail should end (at arrow head base)
        let arrowHeadOffset = cellSize * GameConstants.arrowHeadOffset
        let arrowHeadLength = cellSize * GameConstants.arrowHeadLength
        let tailEndOffset = arrowHeadOffset - arrowHeadLength * 0.3

        // Draw the entire snake body with curves at all turns
        drawSnakeBody(
            context: context,
            snake: snake,
            points: points,
            cellSize: cellSize,
            curveRadius: curveRadius,
            tailEndOffset: tailEndOffset,
            strokeWidth: strokeWidth,
            color: color.opacity(alpha)
        )

        // Draw arrow head at edge of cell
        let arrowHeadPosition = CGPoint(
            x: points[0].x + CGFloat(snake.headDirection.dx) * arrowHeadOffset,
            y: points[0].y + CGFloat(snake.headDirection.dy) * arrowHeadOffset
        )
        drawArrowHead(
            context: context,
            at: arrowHeadPosition,
            direction: snake.headDirection,
            cellSize: cellSize,
            color: color.opacity(alpha)
        )
    }

    private func drawSnakeBody(
        context: GraphicsContext,
        snake: Snake,
        points: [CGPoint],
        cellSize: CGFloat,
        curveRadius: CGFloat,
        tailEndOffset: CGFloat,
        strokeWidth: CGFloat,
        color: Color
    ) {
        guard !points.isEmpty else { return }

        var path = Path()

        if points.count == 1 {
            // Single cell snake - draw short tail
            let headCenter = points[0]
            let tailStart = CGPoint(
                x: headCenter.x - CGFloat(snake.headDirection.dx) * curveRadius,
                y: headCenter.y - CGFloat(snake.headDirection.dy) * curveRadius
            )
            let tailEnd = CGPoint(
                x: headCenter.x + CGFloat(snake.headDirection.dx) * tailEndOffset,
                y: headCenter.y + CGFloat(snake.headDirection.dy) * tailEndOffset
            )
            path.move(to: tailStart)
            path.addLine(to: tailEnd)
        } else {
            // Multi-cell snake - draw with curves at all direction changes
            // Start from the tail and work towards the head

            // Begin at the tail (last point)
            let tailIndex = points.count - 1
            path.move(to: points[tailIndex])

            // Draw segments from tail towards head
            for i in stride(from: tailIndex - 1, through: 0, by: -1) {
                let currentCenter = points[i]

                // Determine incoming direction (from previous cell to current)
                let incomingDir = directionFrom(snake.body[i + 1], to: snake.body[i])

                // Determine outgoing direction
                let outgoingDir: Direction
                if i == 0 {
                    // Head cell - outgoing is the head direction
                    outgoingDir = snake.headDirection
                } else {
                    // Middle cell - outgoing is direction to next cell
                    outgoingDir = directionFrom(snake.body[i], to: snake.body[i - 1])
                }

                let hasTurn = incomingDir != outgoingDir

                if hasTurn {
                    // Draw line to curve start, then curve
                    let curveStart = CGPoint(
                        x: currentCenter.x - CGFloat(incomingDir.dx) * curveRadius,
                        y: currentCenter.y - CGFloat(incomingDir.dy) * curveRadius
                    )

                    let curveEnd: CGPoint
                    if i == 0 {
                        // Head cell - end at arrow head base
                        curveEnd = CGPoint(
                            x: currentCenter.x + CGFloat(outgoingDir.dx) * tailEndOffset,
                            y: currentCenter.y + CGFloat(outgoingDir.dy) * tailEndOffset
                        )
                    } else {
                        // Middle cell - end at edge towards next cell
                        curveEnd = CGPoint(
                            x: currentCenter.x + CGFloat(outgoingDir.dx) * curveRadius,
                            y: currentCenter.y + CGFloat(outgoingDir.dy) * curveRadius
                        )
                    }

                    path.addLine(to: curveStart)
                    path.addQuadCurve(to: curveEnd, control: currentCenter)
                } else {
                    // No turn - draw straight through
                    if i == 0 {
                        // Head cell - end at arrow head base
                        let tailEnd = CGPoint(
                            x: currentCenter.x + CGFloat(outgoingDir.dx) * tailEndOffset,
                            y: currentCenter.y + CGFloat(outgoingDir.dy) * tailEndOffset
                        )
                        path.addLine(to: tailEnd)
                    } else {
                        // Middle cell - continue to next cell center
                        path.addLine(to: currentCenter)
                    }
                }
            }
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
