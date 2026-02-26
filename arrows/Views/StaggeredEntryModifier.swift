//
//  StaggeredEntryModifier.swift
//  arrows
//
//  Shared ViewModifier for staggered fade + slide entry animations
//

import SwiftUI

struct StaggeredEntryModifier: ViewModifier {
    let isVisible: Bool
    let index: Int
    let offset: CGFloat
    let duration: TimeInterval
    let staggerDelay: TimeInterval
    let horizontal: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(
                x: horizontal ? (isVisible ? 0 : offset) : 0,
                y: horizontal ? 0 : (isVisible ? 0 : offset)
            )
            .animation(
                .easeOut(duration: duration)
                    .delay(Double(index) * staggerDelay),
                value: isVisible
            )
    }
}

extension View {
    func homeEntry(isVisible: Bool, index: Int) -> some View {
        modifier(StaggeredEntryModifier(
            isVisible: isVisible,
            index: index,
            offset: GameConstants.homeEnterOffset,
            duration: GameConstants.homeEnterDuration,
            staggerDelay: GameConstants.homeStaggerDelay,
            horizontal: false
        ))
    }

    func settingsEntry(isVisible: Bool, index: Int) -> some View {
        modifier(StaggeredEntryModifier(
            isVisible: isVisible,
            index: index,
            offset: GameConstants.settingsEnterOffset,
            duration: GameConstants.settingsEnterDuration,
            staggerDelay: GameConstants.settingsStaggerDelay,
            horizontal: true
        ))
    }

    func generatorEntry(isVisible: Bool, index: Int) -> some View {
        modifier(StaggeredEntryModifier(
            isVisible: isVisible,
            index: index,
            offset: GameConstants.generatorEnterOffset,
            duration: GameConstants.generatorEnterDuration,
            staggerDelay: GameConstants.generatorStaggerDelay,
            horizontal: false
        ))
    }
}
