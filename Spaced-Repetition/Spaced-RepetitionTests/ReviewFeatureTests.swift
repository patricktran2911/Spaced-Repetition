//
//  ReviewFeatureTests.swift
//  Spaced-RepetitionTests
//
//  Created by Patrick Tran on 1/20/26.
//

import ComposableArchitecture
import XCTest
@testable import Spaced_Repetition

@MainActor
final class ReviewFeatureTests: XCTestCase {
    
    func testShowAnswerTapped() async {
        let item = StudyItemState(id: UUID(), title: "Test", content: "Content")
        
        let store = TestStore(initialState: ReviewFeature.State(item: item)) {
            ReviewFeature()
        }
        
        await store.send(.showAnswerTapped) {
            $0.showAnswer = true
        }
    }
    
    func testRateQuality() async {
        let item = StudyItemState(
            id: UUID(),
            title: "Test",
            content: "Content",
            reviewCount: 0,
            easeFactor: 2.5,
            interval: 0
        )
        
        let testDate = Date()
        
        let store = TestStore(initialState: ReviewFeature.State(
            item: item,
            showAnswer: true,
            startTime: testDate
        )) {
            ReviewFeature()
        } withDependencies: {
            $0.date.now = testDate
            $0.spacedRepetitionClient.calculateNextReview = { easeFactor, interval, quality in
                ReviewResult(
                    nextDate: testDate.addingTimeInterval(86400),
                    newInterval: 1,
                    newEaseFactor: 2.6
                )
            }
            $0.databaseClient.updateStudyItem = { _ in }
            $0.databaseClient.saveReviewSession = { _, _, _ in }
        }
        store.exhaustivity = .off
        
        await store.send(.rateQuality(4)) {
            $0.isSubmitting = true
        }
    }
    
    func testCancelTapped() async {
        let item = StudyItemState(id: UUID(), title: "Test", content: "Content")
        
        let store = TestStore(initialState: ReviewFeature.State(item: item)) {
            ReviewFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect { }
        }
        
        await store.send(.cancelTapped)
    }
    
    func testDefaultState() {
        let item = StudyItemState(id: UUID(), title: "Test", content: "Content")
        let state = ReviewFeature.State(item: item)
        
        XCTAssertFalse(state.showAnswer)
        XCTAssertFalse(state.isSubmitting)
        XCTAssertEqual(state.item.title, "Test")
    }
}
