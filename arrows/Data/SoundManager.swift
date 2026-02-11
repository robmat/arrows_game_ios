//
//  SoundManager.swift
//  arrows
//
//  Audio playback management
//

import Foundation
import AVFoundation

class SoundManager {
    static let shared = SoundManager()

    private var audioPlayer: AVAudioPlayer?
    private var isSoundsEnabled = true

    private init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    func setSoundsEnabled(_ enabled: Bool) {
        isSoundsEnabled = enabled
    }

    func playTapSound() {
        guard isSoundsEnabled else { return }
        playSound(named: "switch\(Int.random(in: 1...30))", extension: "wav")
    }

    func playSnakeRemoved() {
        guard isSoundsEnabled else { return }
        playSound(named: "snake_removed", extension: "mp3")
    }

    func playGameWon() {
        guard isSoundsEnabled else { return }
        playSound(named: "game_won", extension: "mp3")
    }

    func playGameLost() {
        guard isSoundsEnabled else { return }
        playSound(named: "game_lost", extension: "mp3")
    }

    func playPenalty() {
        guard isSoundsEnabled else { return }
        playSound(named: "live_lost", extension: "mp3")
    }

    private func playSound(named name: String, extension ext: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
}
