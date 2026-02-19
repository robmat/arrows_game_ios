//
//  BannerAdView.swift
//  arrows
//
//  SwiftUI banner ad view (standard 320x50 AdMob banner)
//

import GoogleMobileAds
import SwiftUI
import UIKit

struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = AdConstants.bannerAdUnitId
        bannerView.rootViewController = UIApplication.shared.topViewController
        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
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
