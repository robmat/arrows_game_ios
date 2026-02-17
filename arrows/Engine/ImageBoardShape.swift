//
//  ImageBoardShape.swift
//  arrows
//
//  Converts a UIImage silhouette into a board wall grid
//

import UIKit

struct ImageBoardShape: BoardShape {
    let image: UIImage

    func getWalls(width: Int, height: Int) -> [[Bool]] {
        guard let cgImage = image.cgImage else {
            return Array(repeating: Array(repeating: false, count: height), count: width)
        }

        let scaledWidth = width
        let scaledHeight = height

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * scaledWidth
        var pixelData = [UInt8](repeating: 0, count: scaledHeight * bytesPerRow)

        guard let context = CGContext(
            data: &pixelData,
            width: scaledWidth,
            height: scaledHeight,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return Array(repeating: Array(repeating: false, count: height), count: width)
        }

        // Draw white background first (so transparent pixels become walls)
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight))

        // Draw the image scaled to fit
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight))

        // Convert pixels to wall grid
        // walls[x][y]: true = wall, false = playable
        // Black pixels (dark) = playable, non-black = wall
        var walls = Array(repeating: Array(repeating: true, count: height), count: width)

        for x in 0..<scaledWidth {
            for y in 0..<scaledHeight {
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                let r = pixelData[offset]
                let g = pixelData[offset + 1]
                let b = pixelData[offset + 2]

                // Black pixel threshold (matching Android's < 128)
                if r < 128 && g < 128 && b < 128 {
                    walls[x][y] = false // playable
                }
            }
        }

        return walls
    }
}
