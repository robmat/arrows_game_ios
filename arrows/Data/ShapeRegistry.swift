//
//  ShapeRegistry.swift
//  arrows
//
//  Maps shape names to asset catalog image names
//

import UIKit

struct ShapeEntry: Identifiable {
    let id: String
    let displayName: String
    let imageName: String

    var image: UIImage? {
        UIImage(named: imageName)
    }

    func toBoardShape() -> BoardShape? {
        guard let img = image else { return nil }
        return ImageBoardShape(image: img)
    }
}

enum ShapeRegistry {
    static let shapes: [ShapeEntry] = [
        ShapeEntry(id: "bolt", displayName: "Bolt", imageName: "bolt"),
        ShapeEntry(id: "brick", displayName: "Brick", imageName: "brick"),
        ShapeEntry(id: "build", displayName: "Build", imageName: "build"),
        ShapeEntry(id: "cannabis", displayName: "Cannabis", imageName: "cannabis"),
        ShapeEntry(id: "chess_queen", displayName: "Queen", imageName: "chess_queen"),
        ShapeEntry(id: "chess_rook", displayName: "Rook", imageName: "chess_rook"),
        ShapeEntry(id: "delete", displayName: "Delete", imageName: "delete"),
        ShapeEntry(id: "disabled", displayName: "Disabled", imageName: "disabled"),
        ShapeEntry(id: "favorite", displayName: "Favorite", imageName: "favorite"),
        ShapeEntry(id: "home", displayName: "Home", imageName: "home"),
        ShapeEntry(id: "humerus", displayName: "Humerus", imageName: "humerus"),
        ShapeEntry(id: "key", displayName: "Key", imageName: "key"),
        ShapeEntry(id: "star_kid", displayName: "Star Kid", imageName: "star_kid"),
        ShapeEntry(id: "mood_bad", displayName: "Mood Bad", imageName: "mood_bad"),
        ShapeEntry(id: "satisfied", displayName: "Satisfied", imageName: "satisfied"),
        ShapeEntry(id: "settings_shape", displayName: "Settings", imageName: "settings_shape"),
        ShapeEntry(id: "star", displayName: "Star", imageName: "star"),
        ShapeEntry(id: "tibia", displayName: "Tibia", imageName: "tibia"),
        ShapeEntry(id: "water_bottle", displayName: "Bottle", imageName: "water_bottle"),
    ]

    static func boardShape(for id: String) -> BoardShape? {
        shapes.first(where: { $0.id == id })?.toBoardShape()
    }
}
