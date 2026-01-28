//
//  SpacedRepetitionClient.swift
//  Spaced-Repetition
//
//  Created by Patrick Tran on 1/20/26.
//

import Foundation
import ComposableArchitecture

struct ReviewResult: Equatable, Sendable {
    let nextDate: Date
    let newInterval: Int
    let newEaseFactor: Double
}

struct SpacedRepetitionClient: Sendable {
    var calculateNextReview: @Sendable (_ easeFactor: Double, _ interval: Int, _ quality: Int) -> ReviewResult
    var getOptimalReviewTime: @Sendable (_ date: Date) -> Date
}

extension SpacedRepetitionClient: DependencyKey {
    static let liveValue = SpacedRepetitionClient(
        calculateNextReview: { easeFactor, interval, quality in
            // SM-2 Algorithm Implementation
            // Quality: 0-5
            // 0 - Complete blackout
            // 1 - Incorrect, but remembered upon seeing answer
            // 2 - Incorrect, but answer seemed easy to recall
            // 3 - Correct with serious difficulty
            // 4 - Correct with some hesitation
            // 5 - Perfect response
            
            let newEaseFactor = max(1.3, easeFactor + (0.1 - Double(5 - quality) * (0.08 + Double(5 - quality) * 0.02)))
            
            let newInterval: Int
            if quality < 3 {
                // Failed - reset to beginning
                newInterval = 1
            } else if interval == 0 {
                // First review
                newInterval = 1
            } else if interval == 1 {
                // Second review
                newInterval = 6
            } else {
                // Subsequent reviews
                newInterval = Int(Double(interval) * newEaseFactor)
            }
            
            let nextDate = Calendar.current.date(byAdding: .day, value: newInterval, to: Date()) ?? Date()
            
            return ReviewResult(
                nextDate: nextDate,
                newInterval: newInterval,
                newEaseFactor: newEaseFactor
            )
        },
        getOptimalReviewTime: { date in
            // Optimal review times based on research:
            // - Morning (9 AM): Good for immediate recall
            // - Afternoon/Evening (4-9 PM): Best for long-term consolidation
            // - Before sleep: Excellent for memory consolidation
            
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current
            
            // Set to 6 PM (18:00) on the review date - optimal for consolidation
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = 18
            components.minute = 0
            
            return calendar.date(from: components) ?? date
        }
    )
    
    static let testValue = SpacedRepetitionClient(
        calculateNextReview: { _, _, _ in
            ReviewResult(nextDate: Date(), newInterval: 1, newEaseFactor: 2.5)
        },
        getOptimalReviewTime: { date in date }
    )
    
    static let previewValue = liveValue
}

extension DependencyValues {
    var spacedRepetitionClient: SpacedRepetitionClient {
        get { self[SpacedRepetitionClient.self] }
        set { self[SpacedRepetitionClient.self] = newValue }
    }
}