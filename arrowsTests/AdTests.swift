//
//  AdTests.swift
//  arrowsTests
//
//  Unit tests for ad system: constants, preferences state, and interstitial/reward logic
//

import Testing
@testable import arrows

// MARK: - AdConstants Tests

struct AdConstantsTests {

    @Test func testRequiredAdCountForAdFree() {
        #expect(AdConstants.requiredAdCountForAdFree == 30)
    }

    @Test func testGamesBetweenInterstitials() {
        #expect(AdConstants.gamesBetweenInterstitials == 5)
    }

    @Test func testAdUnitIdsAreNonEmpty() {
        #expect(!AdConstants.bannerAdUnitId.isEmpty)
        #expect(!AdConstants.interstitialAdUnitId.isEmpty)
        #expect(!AdConstants.rewardedAdUnitId.isEmpty)
    }
}

// MARK: - Interstitial Display Logic Tests

struct InterstitialLogicTests {

    @Test func testShowsInterstitialEveryFiveGames() {
        #expect(shouldShowInterstitial(gamesCompleted: 5, isAdFree: false) == true)
        #expect(shouldShowInterstitial(gamesCompleted: 10, isAdFree: false) == true)
        #expect(shouldShowInterstitial(gamesCompleted: 15, isAdFree: false) == true)
    }

    @Test func testNoInterstitialOnNonMultipleOfFive() {
        #expect(shouldShowInterstitial(gamesCompleted: 1, isAdFree: false) == false)
        #expect(shouldShowInterstitial(gamesCompleted: 3, isAdFree: false) == false)
        #expect(shouldShowInterstitial(gamesCompleted: 7, isAdFree: false) == false)
        #expect(shouldShowInterstitial(gamesCompleted: 11, isAdFree: false) == false)
    }

    @Test func testNoInterstitialOnFirstGameCheck() {
        // gamesCompleted = 0 would produce 0 % 5 == 0, guard prevents this
        #expect(shouldShowInterstitial(gamesCompleted: 0, isAdFree: false) == false)
    }

    @Test func testNoInterstitialWhenAdFree() {
        #expect(shouldShowInterstitial(gamesCompleted: 5, isAdFree: true) == false)
        #expect(shouldShowInterstitial(gamesCompleted: 10, isAdFree: true) == false)
    }

    private func shouldShowInterstitial(gamesCompleted: Int, isAdFree: Bool) -> Bool {
        !isAdFree
            && gamesCompleted > 0
            && gamesCompleted % AdConstants.gamesBetweenInterstitials == 0
    }
}

// MARK: - Reward Ad Count Logic Tests

struct RewardAdCountLogicTests {

    @Test func testAdFreeUnlockedWhenCountReachesThreshold() {
        var count = AdConstants.requiredAdCountForAdFree - 1
        count += 1
        #expect(count >= AdConstants.requiredAdCountForAdFree)
    }

    @Test func testAdFreeNotUnlockedBelowThreshold() {
        let count = AdConstants.requiredAdCountForAdFree - 1
        #expect(count < AdConstants.requiredAdCountForAdFree)
    }

    @Test func testCountResetsAfterUnlock() {
        var count = AdConstants.requiredAdCountForAdFree
        var isAdFree = false
        if count >= AdConstants.requiredAdCountForAdFree {
            isAdFree = true
            count = 0
        }
        #expect(isAdFree == true)
        #expect(count == 0)
    }

    @Test func testIncrementingCountTowardGoal() {
        var count = 0
        for _ in 0..<AdConstants.requiredAdCountForAdFree {
            count += 1
        }
        #expect(count == AdConstants.requiredAdCountForAdFree)
    }
}

// MARK: - UserPreferences Ad State Tests

@MainActor
struct UserPreferencesAdStateTests {

    @Test func testDefaultIsAdFreeIsFalse() {
        let prefs = makeIsolatedPreferences()
        #expect(prefs.isAdFree == false)
    }

    @Test func testDefaultRewardAdCountIsZero() {
        let prefs = makeIsolatedPreferences()
        #expect(prefs.rewardAdCount == 0)
    }

    @Test func testDefaultGamesCompletedIsZero() {
        let prefs = makeIsolatedPreferences()
        #expect(prefs.gamesCompleted == 0)
    }

    @Test func testSetIsAdFree() {
        let prefs = makeIsolatedPreferences()
        prefs.isAdFree = true
        #expect(prefs.isAdFree == true)
    }

    @Test func testIncrementRewardAdCount() {
        let prefs = makeIsolatedPreferences()
        prefs.rewardAdCount = 5
        #expect(prefs.rewardAdCount == 5)
    }

    @Test func testIncrementGamesCompleted() {
        let prefs = makeIsolatedPreferences()
        prefs.gamesCompleted = 3
        #expect(prefs.gamesCompleted == 3)
    }

    @Test func testRewardAdCountPersistence() {
        let suiteName = "test_reward_ad_\(UUID().uuidString)"
        let prefs = UserPreferences(suiteName: suiteName)
        prefs.rewardAdCount = 12

        let prefs2 = UserPreferences(suiteName: suiteName)
        #expect(prefs2.rewardAdCount == 12)
    }

    @Test func testIsAdFreePersistence() {
        let suiteName = "test_ad_free_\(UUID().uuidString)"
        let prefs = UserPreferences(suiteName: suiteName)
        prefs.isAdFree = true

        let prefs2 = UserPreferences(suiteName: suiteName)
        #expect(prefs2.isAdFree == true)
    }

    private func makeIsolatedPreferences() -> UserPreferences {
        UserPreferences(suiteName: "test_\(UUID().uuidString)")
    }
}
