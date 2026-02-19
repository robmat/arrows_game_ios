//
//  InterstitialAdManager.swift
//  arrows
//
//  Manages loading and presenting interstitial (full-screen) ads
//

import Combine
import GoogleMobileAds
import UIKit

@MainActor
final class InterstitialAdManager: ObservableObject {
    @Published private(set) var isAdLoaded = false
    @Published private(set) var isAdLoading = false

    private var interstitialAd: InterstitialAd?
    private var dismissDelegate: InterstitialDismissDelegate?

    func loadAd() {
        guard !isAdLoading && !isAdLoaded else { return }
        isAdLoading = true

        InterstitialAd.load(
            with: AdConstants.interstitialAdUnitId,
            request: Request()
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
        ad.present(from: rootVC)
    }
}

// MARK: - Private full-screen delegate

private final class InterstitialDismissDelegate: NSObject, FullScreenContentDelegate {
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
