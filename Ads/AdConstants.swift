//
//  AdConstants.swift
//  arrows
//
//  AdMob ad unit IDs and ad flow configuration
//

import Foundation

enum AdConstants {
    // MARK: - Ad Unit IDs
    #if DEBUG
    static let bannerAdUnitId = "ca-app-pub-3940256099942544/2934735716"
    static let interstitialAdUnitId = "ca-app-pub-3940256099942544/4411468910"
    static let rewardedAdUnitId = "ca-app-pub-3940256099942544/1712485313"
    static let admobAppId = "ca-app-pub-3940256099942544~1458002511"
    #else
    static let bannerAdUnitId = "REPLACE_WITH_IOS_BANNER_AD_UNIT_ID"
    static let interstitialAdUnitId = "REPLACE_WITH_IOS_INTERSTITIAL_AD_UNIT_ID"
    static let rewardedAdUnitId = "REPLACE_WITH_IOS_REWARDED_AD_UNIT_ID"
    static let admobAppId = "REPLACE_WITH_IOS_ADMOB_APP_ID"
    #endif

    // MARK: - Ad Flow
    static let requiredAdCountForAdFree = 30
    static let gamesBetweenInterstitials = 5
}
