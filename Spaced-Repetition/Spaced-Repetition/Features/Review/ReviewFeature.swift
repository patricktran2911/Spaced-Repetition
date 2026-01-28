//
//  ReviewFeature.swift
//  Spaced-Repetition
//
//  Created by Patrick Tran on 1/20/26.
//

import Foundation
import ComposableArchitecture

@Reducer
struct ReviewFeature {
    @ObservableState
    struct State: Equatable {
        var item: StudyItemState
        var showAnswer: Bool = false
        var startTime: Date = Date()
        var isSubmitting: Bool = false
    }
    
    enum Action {
        case showAnswerTapped
        case rateQuality(Int)
        case cancelTapped
        case reviewSaved
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case reviewCompleted
        }
    }
    
    @Dependency(\.databaseClient) var databaseClient
    @Dependency(\.spacedRepetitionClient) var spacedRepetitionClient
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.date.now) var now
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .showAnswerTapped:
                state.showAnswer = true
                return .none
                
            case let .rateQuality(quality):
                state.isSubmitting = true
                let responseTime = now.timeIntervalSince(state.startTime)
                
                // Calculate next review using SM-2 algorithm
                let result = spacedRepetitionClient.calculateNextReview(
                    state.item.easeFactor,
                    state.item.interval,
                    quality
                )
                
                // Update local item state
                var updatedItem = state.item
                updatedItem.nextReviewDate = result.nextDate
                updatedItem.interval = result.newInterval
                updatedItem.easeFactor = result.newEaseFactor
                updatedItem.reviewCount += 1
                
                // Extract ALL values BEFORE the async closure to prevent null pointer
                let itemId = updatedItem.id
                let title = updatedItem.title
                let content = updatedItem.content
                let imageData = updatedItem.imageData
                let imagesData = updatedItem.imagesData
                let pdfData = updatedItem.pdfData
                let pdfURL = updatedItem.pdfURL
                let createdAt = updatedItem.createdAt
                let nextReviewDate = updatedItem.nextReviewDate
                let reviewCount = updatedItem.reviewCount
                let easeFactor = updatedItem.easeFactor
                let interval = updatedItem.interval
                let tags = updatedItem.tags
                let capturedQuality = quality
                let capturedResponseTime = responseTime
                
                return .run { send in
                    // Create item inside closure with extracted values
                    let itemToSave = await StudyItemState(
                        id: itemId,
                        title: title,
                        content: content,
                        imageData: imageData,
                        imagesData: imagesData,
                        pdfData: pdfData,
                        pdfURL: pdfURL,
                        createdAt: createdAt,
                        nextReviewDate: nextReviewDate,
                        reviewCount: reviewCount,
                        easeFactor: easeFactor,
                        interval: interval,
                        tags: tags
                    )
                    try await databaseClient.updateStudyItem(itemToSave)
                    try await databaseClient.saveReviewSession(itemId, capturedQuality, capturedResponseTime)
                    await send(.reviewSaved)
                }
                
            case .cancelTapped:
                return .run { _ in
                    await dismiss()
                }
                
            case .reviewSaved:
                return .send(.delegate(.reviewCompleted))
                
            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Quality Rating
enum QualityRating: Int, CaseIterable, Identifiable {
    case blackout = 0
    case incorrect = 1
    case incorrectEasy = 2
    case hard = 3
    case good = 4
    case perfect = 5
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .blackout: return "Blackout"
        case .incorrect: return "Wrong"
        case .incorrectEasy: return "Wrong (Easy)"
        case .hard: return "Hard"
        case .good: return "Good"
        case .perfect: return "Perfect"
        }
    }
    
    var description: String {
        switch self {
        case .blackout: return "Complete blackout, no memory"
        case .incorrect: return "Incorrect, but remembered after"
        case .incorrectEasy: return "Incorrect, but seemed easy"
        case .hard: return "Correct with serious difficulty"
        case .good: return "Correct with some hesitation"
        case .perfect: return "Perfect response"
        }
    }
    
    var color: String {
        switch self {
        case .blackout, .incorrect, .incorrectEasy: return "red"
        case .hard: return "orange"
        case .good: return "yellow"
        case .perfect: return "green"
        }
    }
    
    var systemImage: String {
        switch self {
        case .blackout: return "xmark.circle.fill"
        case .incorrect: return "xmark.circle"
        case .incorrectEasy: return "minus.circle"
        case .hard: return "exclamationmark.circle"
        case .good: return "checkmark.circle"
        case .perfect: return "checkmark.circle.fill"
        }
    }
}
