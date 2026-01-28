//
//  ReviewQueueFeature.swift
//  Spaced-Repetition
//
//  Created by Patrick Tran on 1/20/26.
//

import Foundation
import ComposableArchitecture

@Reducer
struct ReviewQueueFeature {
    @ObservableState
    struct State: Equatable {
        var dueItems: IdentifiedArrayOf<StudyItemState> = []
        var isLoading: Bool = false
        var currentReviewIndex: Int = 0
        @Presents var reviewSession: ReviewFeature.State?
        
        var dueItemsCount: Int {
            dueItems.count
        }
        
        var currentItem: StudyItemState? {
            guard currentReviewIndex < dueItems.count else { return nil }
            return dueItems[currentReviewIndex]
        }
        
        var progress: Double {
            guard !dueItems.isEmpty else { return 0 }
            return Double(currentReviewIndex) / Double(dueItems.count)
        }
    }
    
    enum Action {
        case onAppear
        case onDisappear
        case dueItemsLoaded([StudyItemState])
        case startReviewTapped
        case reviewSession(PresentationAction<ReviewFeature.Action>)
        case refreshItems
        // Stream subscription
        case subscribeToItems
        case streamUpdated([StudyItemState])
    }
    
    
    
    @Dependency(\.databaseClient) var databaseClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .send(.subscribeToItems)
                
            case .onDisappear:
                return .cancel(id: "reviewItemsStream")
                
            case .subscribeToItems:
                return .run { send in
                    let stream = databaseClient.studyItemsStream()
                    for await items in stream {
                        // Filter to only due items
                        let dueItems = items.filter { $0.nextReviewDate <= Date() }
                        await send(.streamUpdated(dueItems))
                    }
                }
                .cancellable(id: "reviewItemsStream", cancelInFlight: true)
                
            case let .streamUpdated(items):
                state.isLoading = false
                let previousCount = state.dueItems.count
                state.dueItems = IdentifiedArray(uniqueElements: items)
                // Reset index if the list changed significantly
                if state.currentReviewIndex >= state.dueItems.count {
                    state.currentReviewIndex = 0
                }
                return .none
                
            case let .dueItemsLoaded(items):
                state.isLoading = false
                state.dueItems = IdentifiedArray(uniqueElements: items)
                state.currentReviewIndex = 0
                return .none
                
            case .startReviewTapped:
                guard let currentItem = state.currentItem else { return .none }
                state.reviewSession = ReviewFeature.State(item: currentItem)
                return .none
                
            case .reviewSession(.presented(.delegate(.reviewCompleted))):
                state.reviewSession = nil
                state.currentReviewIndex += 1
                
                // Check if there are more items
                if state.currentReviewIndex >= state.dueItems.count {
                    state.currentReviewIndex = 0
                }
                // Stream will automatically update via triggerUpdate()
                return .none
                
            case .reviewSession:
                return .none
                
            case .refreshItems:
                return .send(.subscribeToItems)
            }
        }
        .ifLet(\.$reviewSession, action: \.reviewSession) {
            ReviewFeature()
        }
    }
}