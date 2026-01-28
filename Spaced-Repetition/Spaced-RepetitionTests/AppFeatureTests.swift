//
//  AppFeatureTests.swift
//  Spaced-RepetitionTests
//

import ComposableArchitecture
import XCTest
@testable import Spaced_Repetition

@MainActor
final class AppFeatureTests: XCTestCase {
    
    func testDefaultTab() {
        let state = AppFeature.State()
        XCTAssertEqual(state.selectedTab, .items)
    }
    
    func testTabSelection() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        
        await store.send(.binding(.set(\.selectedTab, .review))) {
            $0.selectedTab = .review
        }
        
        await store.send(.binding(.set(\.selectedTab, .stats))) {
            $0.selectedTab = .stats
        }
    }
    
    func testTabRawValues() {
        XCTAssertEqual(AppFeature.State.Tab.items.rawValue, "Library")
        XCTAssertEqual(AppFeature.State.Tab.review.rawValue, "Review")
        XCTAssertEqual(AppFeature.State.Tab.stats.rawValue, "Stats")
    }
    
    func testTabIcons() {
        XCTAssertEqual(AppFeature.State.Tab.items.icon, "books.vertical.fill")
        XCTAssertEqual(AppFeature.State.Tab.review.icon, "book.fill")
        XCTAssertEqual(AppFeature.State.Tab.stats.icon, "chart.bar.fill")
    }
    
    func testInitialChildStates() {
        let state = AppFeature.State()
        XCTAssertEqual(state.studyItems.items.count, 0)
        XCTAssertEqual(state.lectureReview.allItems.count, 0)
        XCTAssertEqual(state.stats.totalItems, 0)
    }
    
    func testOnAppear() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.notificationClient.requestAuthorization = { true }
            $0.notificationClient.scheduleDailyReminder = { _, _ in }
            $0.notificationClient.scheduleReviewReminder = { _, _ in }
            $0.databaseClient.fetchDueItems = { [] }
        }
        
        await store.send(.onAppear)
        
        await store.receive(\.notificationAuthorizationReceived) {
            $0.notificationsEnabled = true
        }
        
        await store.receive(\.scheduleDailyReminder)
        await store.receive(\.checkDueItemsAndNotify)
    }
    
    func testNotificationDisabled() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.notificationClient.requestAuthorization = { false }
            $0.databaseClient.fetchDueItems = { [] }
        }
        
        await store.send(.onAppear)
        
        await store.receive(\.notificationAuthorizationReceived) {
            $0.notificationsEnabled = false
        }
        
        await store.receive(\.checkDueItemsAndNotify)
    }
}
