//
//  RewardedAdManager.swift
//  arrows
//
//  Manages loading and presenting rewarded ads
//

import GoogleMobileAds
import UIKit

@MainActor
final class RewardedAdManager: ObservableObject {
    @Published private(set) var isAdLoaded = false
    @Published private(set) var isAdLoading = false

    private var rewardedAd: GADRewardedAd?
    private var dismissDelegate: RewardedDismissDelegate?

    func loadAd() {
        guard !isAdLoading && !isAdLoaded else { return }
        isAdLoading = true

        GADRewardedAd.load(
            withAdUnitID: AdConstants.rewardedAdUnitId,
            request: GADRequest()
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

        ad.present(fromRootViewController: rootVC) {
            onRewarded()
        }
    }
}

// MARK: - Private full-screen delegate

private final class RewardedDismissDelegate: NSObject, GADFullScreenContentDelegate {
    private let onDismissed: () -> Void

    init(onDismissed: @escaping () -> Void) {
        self.onDismissed = onDismissed
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        onDismissed()
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        onDismissed()
    }
}
