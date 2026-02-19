//
//  RewardedAdManager.swift
//  arrows
//
//  Manages loading and presenting rewarded ads
//

import Combine
import GoogleMobileAds
import UIKit

@MainActor
final class RewardedAdManager: ObservableObject {
    @Published private(set) var isAdLoaded = false
    @Published private(set) var isAdLoading = false

    private var rewardedAd: RewardedAd?
    private var dismissDelegate: RewardedDismissDelegate?

    func loadAd() {
        guard !isAdLoading && !isAdLoaded else { return }
        isAdLoading = true

        RewardedAd.load(
            with: AdConstants.rewardedAdUnitId,
            request: Request()
        ) { [weak self] ad, error in
            guard let self else { return }
            if error != nil {
                self.isAdLoaded = false
                self.isAdLoading = false
                return
            }
            self.rewardedAd = ad
            self.isAdLoaded = true
            self.isAdLoading = false
        }
    }

    func showAd(onRewarded: @escaping () -> Void, onDismissed: @escaping () -> Void) {
        guard let ad = rewardedAd,
              let rootVC = UIApplication.shared.topViewController else {
            loadAd()
            onDismissed()
            return
        }

        isAdLoaded = false
        rewardedAd = nil

        let delegate = RewardedDismissDelegate(onDismissed: { [weak self] in
            onDismissed()
            self?.loadAd()
        })
        dismissDelegate = delegate
        ad.fullScreenContentDelegate = delegate

        ad.present(from: rootVC) {
            onRewarded()
        }
    }
}

// MARK: - Private full-screen delegate

private final class RewardedDismissDelegate: NSObject, FullScreenContentDelegate {
    private let onDismissed: () -> Void

    init(onDismissed: @escaping () -> Void) {
        self.onDismissed = onDismissed
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        onDismissed()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        onDismissed()
    }
}
