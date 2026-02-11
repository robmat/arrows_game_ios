//
//  HapticManager.swift
//  arrows
//
//  Haptic feedback management
//

import UIKit

class HapticManager {
    static let shared = HapticManager()

    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        impactGenerator.prepare()
        notificationGenerator.prepare()
    }

    func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    func error() {
        notificationGenerator.notificationOccurred(.error)
    }

    func impact() {
        impactGenerator.impactOccurred()
    }
}
