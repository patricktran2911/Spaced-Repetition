//
//  SpacedRepetitionClientTests.swift
//  Spaced-RepetitionTests
//
//  Created by Patrick Tran on 1/20/26.
//

import XCTest
@testable import Spaced_Repetition

final class SpacedRepetitionClientTests: XCTestCase {
    
    let client = SpacedRepetitionClient.liveValue
    
    // MARK: - Quality 5 (Perfect) Tests
    
    func testPerfectResponseFirstReview() {
        let result = client.calculateNextReview(2.5, 0, 5)
        
        XCTAssertEqual(result.newInterval, 1)
        XCTAssertEqual(result.newEaseFactor, 2.6, accuracy: 0.01)
    }
    
    func testPerfectResponseSecondReview() {
        let result = client.calculateNextReview(2.5, 1, 5)
        
        XCTAssertEqual(result.newInterval, 6)
        XCTAssertEqual(result.newEaseFactor, 2.6, accuracy: 0.01)
    }
    
    func testPerfectResponseSubsequentReview() {
        let result = client.calculateNextReview(2.5, 6, 5)
        
        // 6 * 2.6 = 15.6 -> 15
        XCTAssertEqual(result.newInterval, 15)
        XCTAssertEqual(result.newEaseFactor, 2.6, accuracy: 0.01)
    }
    
    // MARK: - Quality 4 (Correct with hesitation) Tests
    
    func testQuality4FirstReview() {
        let result = client.calculateNextReview(2.5, 0, 4)
        
        XCTAssertEqual(result.newInterval, 1)
        // EF = 2.5 + (0.1 - (5-4) * (0.08 + (5-4) * 0.02))
        // EF = 2.5 + (0.1 - 1 * (0.08 + 0.02))
        // EF = 2.5 + (0.1 - 0.1) = 2.5
        XCTAssertEqual(result.newEaseFactor, 2.5, accuracy: 0.01)
    }
    
    func testQuality4SubsequentReview() {
        let result = client.calculateNextReview(2.5, 10, 4)
        
        // 10 * 2.5 = 25
        XCTAssertEqual(result.newInterval, 25)
        XCTAssertEqual(result.newEaseFactor, 2.5, accuracy: 0.01)
    }
    
    // MARK: - Quality 3 (Correct with difficulty) Tests
    
    func testQuality3FirstReview() {
        let result = client.calculateNextReview(2.5, 0, 3)
        
        XCTAssertEqual(result.newInterval, 1)
        // EF = 2.5 + (0.1 - (5-3) * (0.08 + (5-3) * 0.02))
        // EF = 2.5 + (0.1 - 2 * (0.08 + 0.04))
        // EF = 2.5 + (0.1 - 0.24) = 2.36
        XCTAssertEqual(result.newEaseFactor, 2.36, accuracy: 0.01)
    }
    
    func testQuality3SubsequentReview() {
        let result = client.calculateNextReview(2.5, 10, 3)
        
        // 10 * 2.36 = 23.6 -> 23
        XCTAssertEqual(result.newInterval, 23)
    }
    
    // MARK: - Quality 2 (Incorrect but familiar) Tests
    
    func testQuality2ResetsInterval() {
        let result = client.calculateNextReview(2.5, 30, 2)
        
        // Quality < 3 resets interval to 1
        XCTAssertEqual(result.newInterval, 1)
        // EF = 2.5 + (0.1 - (5-2) * (0.08 + (5-2) * 0.02))
        // EF = 2.5 + (0.1 - 3 * (0.08 + 0.06))
        // EF = 2.5 + (0.1 - 0.42) = 2.18
        XCTAssertEqual(result.newEaseFactor, 2.18, accuracy: 0.01)
    }
    
    // MARK: - Quality 1 (Incorrect) Tests
    
    func testQuality1ResetsInterval() {
        let result = client.calculateNextReview(2.5, 30, 1)
        
        XCTAssertEqual(result.newInterval, 1)
        // EF = 2.5 + (0.1 - (5-1) * (0.08 + (5-1) * 0.02))
        // EF = 2.5 + (0.1 - 4 * (0.08 + 0.08))
        // EF = 2.5 + (0.1 - 0.64) = 1.96
        XCTAssertEqual(result.newEaseFactor, 1.96, accuracy: 0.01)
    }
    
    // MARK: - Quality 0 (Complete blackout) Tests
    
    func testQuality0ResetsInterval() {
        let result = client.calculateNextReview(2.5, 30, 0)
        
        XCTAssertEqual(result.newInterval, 1)
        // EF = 2.5 + (0.1 - (5-0) * (0.08 + (5-0) * 0.02))
        // EF = 2.5 + (0.1 - 5 * (0.08 + 0.10))
        // EF = 2.5 + (0.1 - 0.9) = 1.7
        XCTAssertEqual(result.newEaseFactor, 1.7, accuracy: 0.01)
    }
    
    // MARK: - Ease Factor Minimum Tests
    
    func testEaseFactorNeverBelowMinimum() {
        // Start with very low ease factor and give bad rating
        let result = client.calculateNextReview(1.3, 10, 0)
        
        // EF should not go below 1.3
        XCTAssertGreaterThanOrEqual(result.newEaseFactor, 1.3)
    }
    
    func testEaseFactorMinimumAfterMultipleBadRatings() {
        var easeFactor = 2.5
        var interval = 1
        
        // Simulate multiple bad ratings
        for _ in 0..<10 {
            let result = client.calculateNextReview(easeFactor, interval, 0)
            easeFactor = result.newEaseFactor
            interval = result.newInterval
        }
        
        XCTAssertGreaterThanOrEqual(easeFactor, 1.3)
    }
    
    // MARK: - Next Date Tests
    
    func testNextDateCalculation() {
        let result = client.calculateNextReview(2.5, 0, 5)
        
        let expectedDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let calendar = Calendar.current
        
        XCTAssertEqual(
            calendar.dateComponents([.year, .month, .day], from: result.nextDate),
            calendar.dateComponents([.year, .month, .day], from: expectedDate)
        )
    }
    
    func testLongIntervalNextDate() {
        let result = client.calculateNextReview(2.5, 100, 5)
        
        // 100 * 2.6 = 260 days
        let expectedDate = Calendar.current.date(byAdding: .day, value: 260, to: Date())!
        let calendar = Calendar.current
        
        XCTAssertEqual(
            calendar.dateComponents([.year, .month, .day], from: result.nextDate),
            calendar.dateComponents([.year, .month, .day], from: expectedDate)
        )
    }
    
    // MARK: - Progression Tests
    
    func testTypicalLearningProgression() {
        var easeFactor = 2.5
        var interval = 0
        
        // First review - quality 4
        var result = client.calculateNextReview(easeFactor, interval, 4)
        XCTAssertEqual(result.newInterval, 1)
        easeFactor = result.newEaseFactor
        interval = result.newInterval
        
        // Second review - quality 4
        result = client.calculateNextReview(easeFactor, interval, 4)
        XCTAssertEqual(result.newInterval, 6)
        easeFactor = result.newEaseFactor
        interval = result.newInterval
        
        // Third review - quality 5
        result = client.calculateNextReview(easeFactor, interval, 5)
        // 6 * 2.6 = 15.6 -> 15
        XCTAssertEqual(result.newInterval, 15)
    }
}
