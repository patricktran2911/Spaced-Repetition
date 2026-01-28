//
//  LectureReviewFeature.swift
//  Spaced-Repetition
//
//  A lecture/note-based review system instead of flashcards.
//  Users can browse, search, and read their full notes, then mark as reviewed.
//

import Foundation
import ComposableArchitecture

@Reducer
struct LectureReviewFeature {
    @ObservableState
    struct State: Equatable {
        var allItems: [StudyItemState] = []
        var dueItems: [StudyItemState] = []
        var searchText: String = ""
        var isLoading: Bool = false
        var selectedItem: StudyItemState?
        var showingReviewSheet: Bool = false
        var filter: Filter = .due
        
        enum Filter: String, CaseIterable, Equatable {
            case due = "Due"
            case all = "All"
            case recent = "Recent"
            
            var icon: String {
                switch self {
                case .due: return "clock.badge.exclamationmark"
                case .all: return "books.vertical"
                case .recent: return "clock.arrow.circlepath"
                }
            }
        }
        
        var filteredItems: [StudyItemState] {
            var items: [StudyItemState]
            
            switch filter {
            case .due:
                items = dueItems
            case .all:
                items = allItems
            case .recent:
                // Items reviewed in the last 7 days
                let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                items = allItems.filter { $0.reviewCount > 0 }.sorted { $0.nextReviewDate > $1.nextReviewDate }
            }
            
            if searchText.isEmpty {
                return items
            }
            
            return items.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        var dueCount: Int { dueItems.count }
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case onDisappear
        case streamUpdated([StudyItemState])
        case selectItem(StudyItemState)
        case dismissItem
        case markAsReviewed(quality: Int)
        case reviewCompleted(StudyItemState)
        case setFilter(State.Filter)
    }
    
    @Dependency(\.databaseClient) var databaseClient
    @Dependency(\.spacedRepetitionClient) var spacedRepetitionClient
    @Dependency(\.date.now) var now
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    let stream = databaseClient.studyItemsStream()
                    for await items in stream {
                        await send(.streamUpdated(items))
                    }
                }
                .cancellable(id: "lectureReviewStream", cancelInFlight: true)
                
            case .onDisappear:
                return .cancel(id: "lectureReviewStream")
                
            case let .streamUpdated(items):
                state.isLoading = false
                state.allItems = items
                state.dueItems = items.filter { $0.nextReviewDate <= Date() }
                return .none
                
            case let .selectItem(item):
                state.selectedItem = item
                state.showingReviewSheet = true
                return .none
                
            case .dismissItem:
                state.selectedItem = nil
                state.showingReviewSheet = false
                return .none
                
            case let .markAsReviewed(quality):
                guard let item = state.selectedItem else { return .none }
                
                // Calculate next review using SM-2 algorithm
                let result = spacedRepetitionClient.calculateNextReview(
                    item.easeFactor,
                    item.interval,
                    quality
                )
                
                // Create updated item
                var updatedItem = item
                updatedItem.nextReviewDate = result.nextDate
                updatedItem.interval = result.newInterval
                updatedItem.easeFactor = result.newEaseFactor
                updatedItem.reviewCount += 1
                
                state.selectedItem = nil
                state.showingReviewSheet = false
                
                // Extract values for async closure
                let itemId = updatedItem.id
                let title = updatedItem.title
                let content = updatedItem.content
                let imageData = updatedItem.imageData
                let imagesData = updatedItem.imagesData
                let pdfData = updatedItem.pdfData
                let pdfURL = updatedItem.pdfURL
                let nextReviewDate = updatedItem.nextReviewDate
                let reviewCount = updatedItem.reviewCount
                let easeFactor = updatedItem.easeFactor
                let interval = updatedItem.interval
                let tags = updatedItem.tags
                let createdAt = updatedItem.createdAt
                
                return .run { send in
                    let itemToSave = StudyItemState(
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
                    try await databaseClient.saveReviewSession(itemId, quality, 0)
                    await send(.reviewCompleted(itemToSave))
                }
                
            case .reviewCompleted:
                // Stream will update the list automatically
                return .none
                
            case let .setFilter(filter):
                state.filter = filter
                return .none
            }
        }
    }
}
