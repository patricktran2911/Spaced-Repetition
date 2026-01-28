//
//  PracticeFeature.swift
//  Spaced-Repetition
//
//  Practice mode allows users to review cards anytime without affecting the spaced repetition schedule.
//

import Foundation
import ComposableArchitecture

@Reducer
struct PracticeFeature {
    @ObservableState
    struct State: Equatable {
        var items: [StudyItemState] = []
        var allItems: [StudyItemState] = []
        var currentIndex: Int = 0
        var isFlipped: Bool = false
        var isLoading: Bool = false
        var practiceMode: PracticeMode = .all
        var shuffled: Bool = true
        
        var currentItem: StudyItemState? {
            guard currentIndex >= 0 && currentIndex < items.count else { return nil }
            return items[currentIndex]
        }
        
        var progress: Double {
            guard !items.isEmpty else { return 0 }
            return Double(currentIndex) / Double(items.count)
        }
        
        var remainingCount: Int {
            max(0, items.count - currentIndex)
        }
    }
    
    enum PracticeMode: String, CaseIterable, Equatable {
        case all = "All Cards"
        case due = "Due Cards"
        case random = "Random 10"
        case difficult = "Difficult"
        
        var icon: String {
            switch self {
            case .all: return "square.stack.3d.up"
            case .due: return "clock"
            case .random: return "shuffle"
            case .difficult: return "exclamationmark.triangle"
            }
        }
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case onDisappear
        case itemsLoaded([StudyItemState])
        case flipCard
        case nextCard
        case previousCard
        case shuffleCards
        case changePracticeMode(PracticeMode)
        case restartPractice
        case knowIt
        case needsWork
        case subscribeToItems
        case streamUpdated([StudyItemState])
    }
    
    
    
    @Dependency(\.databaseClient) var databaseClient
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .onAppear:
                state.isLoading = true
                return .send(.subscribeToItems)
                
            case .onDisappear:
                return .cancel(id: "practiceItemsStream")
                
            case .subscribeToItems:
                return .run { send in
                    let stream = await databaseClient.studyItemsStream()
                    for await items in stream {
                        await send(.streamUpdated(items))
                    }
                }
                .cancellable(id: "practiceItemsStream", cancelInFlight: true)
                
            case let .streamUpdated(items):
                state.isLoading = false
                state.allItems = items
                state.items = filterItems(items, mode: state.practiceMode)
                if state.shuffled {
                    state.items.shuffle()
                }
                if state.currentIndex >= state.items.count {
                    state.currentIndex = 0
                }
                return .none
                
            case let .itemsLoaded(items):
                state.isLoading = false
                state.allItems = items
                state.items = filterItems(items, mode: state.practiceMode)
                if state.shuffled {
                    state.items.shuffle()
                }
                state.currentIndex = 0
                state.isFlipped = false
                return .none
                
            case .flipCard:
                state.isFlipped.toggle()
                return .none
                
            case .nextCard:
                if state.currentIndex < state.items.count - 1 {
                    state.currentIndex += 1
                    state.isFlipped = false
                }
                return .none
                
            case .previousCard:
                if state.currentIndex > 0 {
                    state.currentIndex -= 1
                    state.isFlipped = false
                }
                return .none
                
            case .shuffleCards:
                state.items.shuffle()
                state.currentIndex = 0
                state.isFlipped = false
                return .none
                
            case let .changePracticeMode(mode):
                state.practiceMode = mode
                state.items = filterItems(state.allItems, mode: mode)
                if state.shuffled {
                    state.items.shuffle()
                }
                state.currentIndex = 0
                state.isFlipped = false
                return .none
                
            case .restartPractice:
                if state.shuffled {
                    state.items.shuffle()
                }
                state.currentIndex = 0
                state.isFlipped = false
                return .none
                
            case .knowIt:
                state.isFlipped = false
                if state.currentIndex < state.items.count - 1 {
                    state.currentIndex += 1
                }
                return .none
                
            case .needsWork:
                state.isFlipped = false
                if state.currentIndex < state.items.count - 1 {
                    state.currentIndex += 1
                }
                return .none
            }
        }
    }
    
    private func filterItems(_ items: [StudyItemState], mode: PracticeMode) -> [StudyItemState] {
        switch mode {
        case .all:
            return items
        case .due:
            return items.filter { $0.isDue }
        case .random:
            return Array(items.shuffled().prefix(10))
        case .difficult:
            return items.filter { $0.easeFactor < 2.0 }
        }
    }
}
