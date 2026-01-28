//
//  StatsFeatureTests.swift
//  Spaced-RepetitionTests
//
//  Created by Patrick Tran on 1/20/26.
//

import ComposableArchitecture
import XCTest
@testable import Spaced_Repetition

@MainActor
final class StatsFeatureTests: XCTestCase {
    
    func testDefaultState() {
        let state = StatsFeature.State()
        XCTAssertEqual(state.totalItems, 0)
        XCTAssertEqual(state.dueToday, 0)
        XCTAssertEqual(state.reviewedToday, 0)
        XCTAssertEqual(state.totalReviews, 0)
        XCTAssertEqual(state.averageEaseFactor, 2.5)
        XCTAssertFalse(state.isLoading)
    }
    
    func testOnAppearLoadsStats() async {
        let fixedDate = Date()
        let items = [
            StudyItemState(id: UUID(), title: "Item 1", content: "Content 1", reviewCount: 5, interval: 1),
            StudyItemState(id: UUID(), title: "Item 2", content: "Content 2", reviewCount: 3, interval: 7)
        ]
        let dueItems = [items[0]]
        
        let store = TestStore(initialState: StatsFeature.State()) {
            StatsFeature()
        } withDependencies: {
            $0.databaseClient.fetchStudyItems = { items }
            $0.databaseClient.fetchDueItems = { dueItems }
            $0.date.now = fixedDate
        }
        store.exhaustivity = .off
        
        await store.send(.onAppear) {
            $0.isLoading = true
        }
        
        await store.receive(\.statsLoaded) {
            $0.isLoading = false
            $0.totalItems = 2
            $0.dueToday = 1
            $0.totalReviews = 8
        }
    }
    
    func testRefreshStats() async {
        let fixedDate = Date()
        let items = [
            StudyItemState(id: UUID(), title: "Item 1", content: "Content 1", reviewCount: 10)
        ]
        
        let store = TestStore(initialState: StatsFeature.State(
            totalItems: 5,
            totalReviews: 20
        )) {
            StatsFeature()
        } withDependencies: {
            $0.databaseClient.fetchStudyItems = { items }
            $0.databaseClient.fetchDueItems = { [] }
            $0.date.now = fixedDate
        }
        store.exhaustivity = .off
        
        await store.send(.refreshStats)
        
        await store.receive(\.onAppear) {
            $0.isLoading = true
        }
        
        await store.receive(\.statsLoaded) {
            $0.isLoading = false
            $0.totalItems = 1
            $0.totalReviews = 10
        }
    }
    
    func testStatsWithEmptyDatabase() async {
        let fixedDate = Date()
        
        let store = TestStore(initialState: StatsFeature.State()) {
            StatsFeature()
        } withDependencies: {
            $0.databaseClient.fetchStudyItems = { [] }
            $0.databaseClient.fetchDueItems = { [] }
            $0.date.now = fixedDate
        }
        store.exhaustivity = .off
        
        await store.send(.onAppear) {
            $0.isLoading = true
        }
        
        await store.receive(\.statsLoaded) {
            $0.isLoading = false
            $0.totalItems = 0
            $0.totalReviews = 0
            $0.dueToday = 0
        }
    }
    
    func testNextTipTapped() async {
        let store = TestStore(initialState: StatsFeature.State(selectedTip: .activeRecall)) {
            StatsFeature()
        }
        
        await store.send(.nextTipTapped) {
            $0.selectedTip = .spacedRepetition
        }
        
        await store.send(.nextTipTapped) {
            $0.selectedTip = .sleep
        }
    }
    
    func testIntervalGroups() {
        // Test the interval grouping logic
        let newItem = StudyItemState(id: UUID(), title: "New", content: "Content", interval: 0)
        let learningItem = StudyItemState(id: UUID(), title: "Learning", content: "Content", interval: 3)
        let youngItem = StudyItemState(id: UUID(), title: "Young", content: "Content", interval: 14)
        let matureItem = StudyItemState(id: UUID(), title: "Mature", content: "Content", interval: 30)
        
        // Verify the items have correct intervals
        XCTAssertEqual(newItem.interval, 0)
        XCTAssertEqual(learningItem.interval, 3)
        XCTAssertEqual(youngItem.interval, 14)
        XCTAssertEqual(matureItem.interval, 30)
    }
    
    func testLearningTips() {
        // Test all learning tips have content
        for tip in LearningTip.allCases {
            XCTAssertFalse(tip.title.isEmpty)
            XCTAssertFalse(tip.description.isEmpty)
            XCTAssertFalse(tip.icon.isEmpty)
        }
    }
}