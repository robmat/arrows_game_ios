//
//  BannerAdView.swift
//  arrows
//
//  SwiftUI banner ad view (320x50 AdMob standard banner)
//

import GoogleMobileAds
import SwiftUI
import UIKit

struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = AdConstants.bannerAdUnitId
        bannerView.rootViewController = UIApplication.shared.topViewController
        bannerView.load(GADRequest())
        return bannerView
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}

// MARK: - UIApplication helper

extension UIApplication {
    var topViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .compactMap { $0.windows.first { $0.isKeyWindow } }
            .first?
            .rootViewController
    }
}
