//
//  ReviewQueueFeatureTests.swift
//  Spaced-RepetitionTests
//
//  Created by Patrick Tran on 1/20/26.
//

import ComposableArchitecture
import XCTest
@testable import Spaced_Repetition

@MainActor
final class ReviewQueueFeatureTests: XCTestCase {
    
    func testOnAppearLoadsDueItems() async {
        let dueItems = [
            StudyItemState(id: UUID(), title: "Due 1", content: "Content 1"),
            StudyItemState(id: UUID(), title: "Due 2", content: "Content 2")
        ]
        
        let store = TestStore(initialState: ReviewQueueFeature.State()) {
            ReviewQueueFeature()
        } withDependencies: {
            $0.databaseClient.fetchDueItems = { dueItems }
        }
        
        await store.send(.onAppear) {
            $0.isLoading = true
        }
        
        await store.receive(\.dueItemsLoaded) {
            $0.isLoading = false
            $0.dueItems = IdentifiedArray(uniqueElements: dueItems)
            $0.currentReviewIndex = 0
        }
    }
    
    func testStartReviewTapped() async {
        let dueItem = StudyItemState(id: UUID(), title: "Due", content: "Content")
        
        let store = TestStore(initialState: ReviewQueueFeature.State(
            dueItems: IdentifiedArray(uniqueElements: [dueItem])
        )) {
            ReviewQueueFeature()
        }
        store.exhaustivity = .off
        
        await store.send(.startReviewTapped)
    }
    
    func testStartReviewTappedWithEmptyQueue() async {
        let store = TestStore(initialState: ReviewQueueFeature.State(
            dueItems: []
        )) {
            ReviewQueueFeature()
        }
        
        await store.send(.startReviewTapped)
        // No state change since queue is empty
    }
    
    func testReviewCompletedMovesToNextItem() async {
        let item1 = StudyItemState(id: UUID(), title: "Item 1", content: "Content 1")
        let item2 = StudyItemState(id: UUID(), title: "Item 2", content: "Content 2")
        
        let store = TestStore(initialState: ReviewQueueFeature.State(
            dueItems: IdentifiedArray(uniqueElements: [item1, item2]),
            currentReviewIndex: 0,
            reviewSession: ReviewFeature.State(item: item1)
        )) {
            ReviewQueueFeature()
        }
        
        await store.send(.reviewSession(.presented(.delegate(.reviewCompleted)))) {
            $0.reviewSession = nil
            $0.currentReviewIndex = 1
        }
    }
    
    func testReviewCompletedRefreshesWhenAllDone() async {
        let item = StudyItemState(id: UUID(), title: "Item", content: "Content")
        
        let store = TestStore(initialState: ReviewQueueFeature.State(
            dueItems: IdentifiedArray(uniqueElements: [item]),
            currentReviewIndex: 0,
            reviewSession: ReviewFeature.State(item: item)
        )) {
            ReviewQueueFeature()
        } withDependencies: {
            $0.databaseClient.fetchDueItems = { [] }
        }
        
        await store.send(.reviewSession(.presented(.delegate(.reviewCompleted)))) {
            $0.reviewSession = nil
            $0.currentReviewIndex = 1
        }
        
        await store.receive(\.refreshItems) {
            $0.isLoading = true
        }
        
        await store.receive(\.dueItemsLoaded) {
            $0.isLoading = false
            $0.dueItems = []
            $0.currentReviewIndex = 0
        }
    }
    
    func testProgressCalculation() {
        let item1 = StudyItemState(id: UUID(), title: "Item 1", content: "Content 1")
        let item2 = StudyItemState(id: UUID(), title: "Item 2", content: "Content 2")
        let item3 = StudyItemState(id: UUID(), title: "Item 3", content: "Content 3")
        
        var state = ReviewQueueFeature.State(
            dueItems: IdentifiedArray(uniqueElements: [item1, item2, item3]),
            currentReviewIndex: 1
        )
        
        XCTAssertEqual(state.progress, 1.0 / 3.0, accuracy: 0.01)
        
        state.currentReviewIndex = 2
        XCTAssertEqual(state.progress, 2.0 / 3.0, accuracy: 0.01)
    }
    
    func testProgressWithEmptyQueue() {
        let state = ReviewQueueFeature.State(dueItems: [])
        XCTAssertEqual(state.progress, 0.0)
    }
    
    func testCurrentItem() {
        let item1 = StudyItemState(id: UUID(), title: "Item 1", content: "Content 1")
        let item2 = StudyItemState(id: UUID(), title: "Item 2", content: "Content 2")
        
        var state = ReviewQueueFeature.State(
            dueItems: IdentifiedArray(uniqueElements: [item1, item2]),
            currentReviewIndex: 0
        )
        
        XCTAssertEqual(state.currentItem?.title, "Item 1")
        
        state.currentReviewIndex = 1
        XCTAssertEqual(state.currentItem?.title, "Item 2")
        
        state.currentReviewIndex = 2
        XCTAssertNil(state.currentItem)
    }
    
    func testDueItemsCount() {
        let item1 = StudyItemState(id: UUID(), title: "Item 1", content: "Content 1")
        let item2 = StudyItemState(id: UUID(), title: "Item 2", content: "Content 2")
        
        let state = ReviewQueueFeature.State(
            dueItems: IdentifiedArray(uniqueElements: [item1, item2])
        )
        
        XCTAssertEqual(state.dueItemsCount, 2)
    }
}
