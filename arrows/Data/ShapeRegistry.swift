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
        ShapeEntry(id: "bolt", displayName: AppStrings.ShapeName.bolt, imageName: "bolt"),
        ShapeEntry(id: "brick", displayName: AppStrings.ShapeName.brick, imageName: "brick"),
        ShapeEntry(id: "build", displayName: AppStrings.ShapeName.build, imageName: "build"),
        ShapeEntry(id: "cannabis", displayName: AppStrings.ShapeName.cannabis, imageName: "cannabis"),
        ShapeEntry(id: "chess_queen", displayName: AppStrings.ShapeName.queen, imageName: "chess_queen"),
        ShapeEntry(id: "chess_rook", displayName: AppStrings.ShapeName.rook, imageName: "chess_rook"),
        ShapeEntry(id: "delete", displayName: AppStrings.ShapeName.delete, imageName: "delete"),
        ShapeEntry(id: "disabled", displayName: AppStrings.ShapeName.disabled, imageName: "disabled"),
        ShapeEntry(id: "favorite", displayName: AppStrings.ShapeName.favorite, imageName: "favorite"),
        ShapeEntry(id: "home", displayName: AppStrings.ShapeName.home, imageName: "home"),
        ShapeEntry(id: "humerus", displayName: AppStrings.ShapeName.humerus, imageName: "humerus"),
        ShapeEntry(id: "key", displayName: AppStrings.ShapeName.key, imageName: "key"),
        ShapeEntry(id: "star_kid", displayName: AppStrings.ShapeName.starKid, imageName: "star_kid"),
        ShapeEntry(id: "mood_bad", displayName: AppStrings.ShapeName.moodBad, imageName: "mood_bad"),
        ShapeEntry(id: "satisfied", displayName: AppStrings.ShapeName.satisfied, imageName: "satisfied"),
        ShapeEntry(id: "settings_shape", displayName: AppStrings.ShapeName.settings, imageName: "settings_shape"),
        ShapeEntry(id: "star", displayName: AppStrings.ShapeName.star, imageName: "star"),
        ShapeEntry(id: "tibia", displayName: AppStrings.ShapeName.tibia, imageName: "tibia"),
        ShapeEntry(id: "water_bottle", displayName: AppStrings.ShapeName.bottle, imageName: "water_bottle"),
    ]

    static func boardShape(for id: String) -> BoardShape? {
        shapes.first(where: { $0.id == id })?.toBoardShape()
    }
}
