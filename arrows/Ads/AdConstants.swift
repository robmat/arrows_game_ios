//
//  AdConstants.swift
//  arrows
//
//  AdMob ad unit IDs and ad flow configuration
//

import Foundation

enum AdConstants {
    // MARK: - Ad Unit IDs
    // Debug uses Google's official test ad unit IDs (safe for development)
    // Release: replace with your real iOS ad unit IDs from the AdMob console
    #if DEBUG
    static let bannerAdUnitId = "ca-app-pub-3940256099942544/2934735716"
    static let interstitialAdUnitId = "ca-app-pub-3940256099942544/4411468910"
    static let rewardedAdUnitId = "ca-app-pub-3940256099942544/1712485313"
    #else
    static let bannerAdUnitId = "REPLACE_WITH_IOS_BANNER_AD_UNIT_ID"
    static let interstitialAdUnitId = "REPLACE_WITH_IOS_INTERSTITIAL_AD_UNIT_ID"
    static let rewardedAdUnitId = "REPLACE_WITH_IOS_REWARDED_AD_UNIT_ID"
    #endif
    // App ID is set via ADMOB_APP_ID build setting → arrows/Info.plist → GADApplicationIdentifier

    // MARK: - Ad Flow
    static let requiredAdCountForAdFree = 30
    static let gamesBetweenInterstitials = 5
}
