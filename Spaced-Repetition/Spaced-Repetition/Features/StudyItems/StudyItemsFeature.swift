//
//  StudyItemsFeature.swift
//  Spaced-Repetition
//
//  Created by Patrick Tran on 1/20/26.
//

import Foundation
import ComposableArchitecture

@Reducer
struct StudyItemsFeature {
    @ObservableState
    struct State: Equatable {
        var items: IdentifiedArrayOf<StudyItemState> = []
        var isLoading: Bool = false
        var searchText: String = ""
        var selectedItemId: UUID?
        @Presents var addItem: AddStudyItemFeature.State?
        @Presents var detail: StudyItemDetailFeature.State?
        
        var filteredItems: IdentifiedArrayOf<StudyItemState> {
            if searchText.isEmpty {
                return items
            }
            return items.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        var dueItemsCount: Int {
            items.filter { $0.nextReviewDate <= Date() }.count
        }
        
        var selectedItem: StudyItemState? {
            guard let id = selectedItemId else { return nil }
            return items[id: id]
        }
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case itemsLoaded([StudyItemState])
        case addItemTapped
        case deleteItem(id: UUID)
        case itemTapped(StudyItemState)
        case selectItem(UUID?)
        case addItem(PresentationAction<AddStudyItemFeature.Action>)
        case detail(PresentationAction<StudyItemDetailFeature.Action>)
        case refreshItems
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
                return .run { send in
                    let items = try await databaseClient.fetchStudyItems()
                    await send(.itemsLoaded(items))
                }
                
            case let .itemsLoaded(items):
                state.isLoading = false
                state.items = IdentifiedArray(uniqueElements: items)
                // Auto-select first item if none selected
                if state.selectedItemId == nil, let firstItem = items.first {
                    state.selectedItemId = firstItem.id
                }
                return .none
                
            case .addItemTapped:
                state.addItem = AddStudyItemFeature.State()
                return .none
                
            case let .deleteItem(id):
                // If deleting selected item, select next or previous
                if state.selectedItemId == id {
                    if let index = state.items.index(id: id) {
                        if index + 1 < state.items.count {
                            state.selectedItemId = state.items[index + 1].id
                        } else if index > 0 {
                            state.selectedItemId = state.items[index - 1].id
                        } else {
                            state.selectedItemId = nil
                        }
                    }
                }
                state.items.remove(id: id)
                return .run { _ in
                    try await databaseClient.deleteStudyItem(id)
                }
                
            case let .itemTapped(item):
                state.selectedItemId = item.id
                state.detail = StudyItemDetailFeature.State(item: item)
                return .none
                
            case let .selectItem(id):
                state.selectedItemId = id
                if let id = id, let item = state.items[id: id] {
                    state.detail = StudyItemDetailFeature.State(item: item)
                } else {
                    state.detail = nil
                }
                return .none
                
            case .addItem(.presented(.delegate(.itemSaved))):
                state.addItem = nil
                return .send(.refreshItems)
                
            case .detail(.presented(.delegate(.itemUpdated))):
                return .send(.refreshItems)
                
            case .detail(.presented(.delegate(.itemDeleted))):
                state.detail = nil
                return .send(.refreshItems)
                
            case .addItem, .detail:
                return .none
                
            case .refreshItems:
                return .run { send in
                    let items = try await databaseClient.fetchStudyItems()
                    await send(.itemsLoaded(items))
                }
            }
        }
        .ifLet(\.$addItem, action: \.addItem) {
            AddStudyItemFeature()
        }
        .ifLet(\.$detail, action: \.detail) {
            StudyItemDetailFeature()
        }
    }
}
