//
//  StudyItemsFeatureTests.swift
//  Spaced-RepetitionTests
//
//  Created by Patrick Tran on 1/20/26.
//

import ComposableArchitecture
import XCTest
@testable import Spaced_Repetition

@MainActor
final class StudyItemsFeatureTests: XCTestCase {
    
    func testOnAppearLoadsItems() async {
        let mockItems = [
            StudyItemState(id: UUID(), title: "Test 1", content: "Content 1"),
            StudyItemState(id: UUID(), title: "Test 2", content: "Content 2")
        ]
        
        let store = TestStore(initialState: StudyItemsFeature.State()) {
            StudyItemsFeature()
        } withDependencies: {
            $0.databaseClient.fetchStudyItems = { mockItems }
        }
        
        await store.send(.onAppear) {
            $0.isLoading = true
        }
        
        await store.receive(\.itemsLoaded) {
            $0.isLoading = false
            $0.items = IdentifiedArray(uniqueElements: mockItems)
        }
    }
    
    func testAddItemTapped() async {
        let store = TestStore(initialState: StudyItemsFeature.State()) {
            StudyItemsFeature()
        }
        
        await store.send(.addItemTapped) {
            $0.addItem = AddStudyItemFeature.State()
        }
    }
    
    func testDeleteItem() async {
        let itemId = UUID()
        let mockItem = StudyItemState(id: itemId, title: "Test", content: "Content")
        
        let store = TestStore(initialState: StudyItemsFeature.State(
            items: IdentifiedArray(uniqueElements: [mockItem])
        )) {
            StudyItemsFeature()
        } withDependencies: {
            $0.databaseClient.deleteStudyItem = { _ in }
        }
        
        await store.send(.deleteItem(id: itemId)) {
            $0.items = []
        }
    }
    
    func testItemTapped() async {
        let mockItem = StudyItemState(id: UUID(), title: "Test", content: "Content")
        
        let store = TestStore(initialState: StudyItemsFeature.State(
            items: IdentifiedArray(uniqueElements: [mockItem])
        )) {
            StudyItemsFeature()
        }
        
        await store.send(.itemTapped(mockItem)) {
            $0.detail = StudyItemDetailFeature.State(item: mockItem)
        }
    }
    
    func testFilteredItems() {
        let item1 = StudyItemState(id: UUID(), title: "Swift Basics", content: "Content")
        let item2 = StudyItemState(id: UUID(), title: "Python", content: "Content")
        
        var state = StudyItemsFeature.State(
            items: IdentifiedArray(uniqueElements: [item1, item2]),
            searchText: "Swift"
        )
        
        XCTAssertEqual(state.filteredItems.count, 1)
        XCTAssertEqual(state.filteredItems.first?.title, "Swift Basics")
        
        state.searchText = ""
        XCTAssertEqual(state.filteredItems.count, 2)
    }
    
    func testDueItemsCount() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        let dueItem = StudyItemState(id: UUID(), title: "Due", content: "Content", nextReviewDate: pastDate)
        let notDueItem = StudyItemState(id: UUID(), title: "Not Due", content: "Content", nextReviewDate: futureDate)
        
        let state = StudyItemsFeature.State(
            items: IdentifiedArray(uniqueElements: [dueItem, notDueItem])
        )
        
        XCTAssertEqual(state.dueItemsCount, 1)
    }
    
    func testRefreshItems() async {
        let mockItems = [
            StudyItemState(id: UUID(), title: "Refreshed", content: "Content")
        ]
        
        let store = TestStore(initialState: StudyItemsFeature.State()) {
            StudyItemsFeature()
        } withDependencies: {
            $0.databaseClient.fetchStudyItems = { mockItems }
        }
        
        await store.send(.refreshItems)
        
        await store.receive(\.itemsLoaded) {
            $0.isLoading = false
            $0.items = IdentifiedArray(uniqueElements: mockItems)
        }
    }
    
    func testItemSavedDelegateRefreshesItems() async {
        let mockItems = [
            StudyItemState(id: UUID(), title: "New Item", content: "Content")
        ]
        
        let store = TestStore(initialState: StudyItemsFeature.State(
            addItem: AddStudyItemFeature.State()
        )) {
            StudyItemsFeature()
        } withDependencies: {
            $0.databaseClient.fetchStudyItems = { mockItems }
        }
        
        await store.send(.addItem(.presented(.delegate(.itemSaved)))) {
            $0.addItem = nil
        }
        
        await store.receive(\.refreshItems)
        
        await store.receive(\.itemsLoaded) {
            $0.isLoading = false
            $0.items = IdentifiedArray(uniqueElements: mockItems)
        }
    }
}
