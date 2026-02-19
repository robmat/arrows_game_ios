//
//  InterstitialAdManager.swift
//  arrows
//
//  Manages loading and presenting interstitial (full-screen) ads
//

import GoogleMobileAds
import UIKit

@MainActor
final class InterstitialAdManager: ObservableObject {
    @Published private(set) var isAdLoaded = false
    @Published private(set) var isAdLoading = false

    private var interstitialAd: GADInterstitialAd?
    private var dismissDelegate: InterstitialDismissDelegate?

    func loadAd() {
        guard !isAdLoading && !isAdLoaded else { return }
        isAdLoading = true

        GADInterstitialAd.load(
            withAdUnitID: AdConstants.interstitialAdUnitId,
            request: GADRequest()
        ) { [weak self] ad, error in
            guard let self else { return }
            if error != nil {
                self.isAdLoaded = false
                self.isAdLoading = false
                return
            }
            self.interstitialAd = ad
            self.isAdLoaded = true
            self.isAdLoading = false
        }
    }

    func showAd(onDismissed: @escaping () -> Void) {
        guard let ad = interstitialAd,
              let rootVC = UIApplication.shared.topViewController else {
            loadAd()
            onDismissed()
            return
        }

        isAdLoaded = false
        interstitialAd = nil

        let delegate = InterstitialDismissDelegate(onDismissed: { [weak self] in
            onDismissed()
            self?.loadAd()
        })
        dismissDelegate = delegate
        ad.fullScreenContentDelegate = delegate
        ad.present(fromRootViewController: rootVC)
    }
}

// MARK: - Private full-screen delegate

private final class InterstitialDismissDelegate: NSObject, GADFullScreenContentDelegate {
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
