//
//  StudyItemDetailFeatureTests.swift
//  Spaced-RepetitionTests
//
//  Created by Patrick Tran on 1/20/26.
//

import ComposableArchitecture
import XCTest
@testable import Spaced_Repetition

@MainActor
final class StudyItemDetailFeatureTests: XCTestCase {
    
    func testEditButtonTapped() async {
        let item = StudyItemState(id: UUID(), title: "Test", content: "Content", tags: ["swift"])
        
        let store = TestStore(initialState: StudyItemDetailFeature.State(item: item)) {
            StudyItemDetailFeature()
        }
        
        await store.send(.editButtonTapped) {
            $0.isEditing = true
            $0.editedTitle = "Test"
            $0.editedContent = "Content"
            $0.editedTags = ["swift"]
            $0.editedImagesData = []
            $0.editedPdfData = nil
        }
    }
    
    func testCancelEditTapped() async {
        let item = StudyItemState(id: UUID(), title: "Test", content: "Content")
        
        let store = TestStore(initialState: StudyItemDetailFeature.State(
            item: item,
            isEditing: true,
            editedTitle: "Changed Title",
            editedContent: "Changed Content"
        )) {
            StudyItemDetailFeature()
        }
        
        await store.send(.cancelEditTapped) {
            $0.isEditing = false
        }
    }
    
    func testSaveEditTappedWithEmptyInput() async {
        let item = StudyItemState(id: UUID(), title: "Test", content: "Content")
        
        let store = TestStore(initialState: StudyItemDetailFeature.State(
            item: item,
            isEditing: true,
            editedTitle: "",
            editedContent: ""
        )) {
            StudyItemDetailFeature()
        }
        
        await store.send(.saveEditTapped)
    }
    
    func testDeleteButtonTapped() async {
        let item = StudyItemState(id: UUID(), title: "Test", content: "Content")
        
        let store = TestStore(initialState: StudyItemDetailFeature.State(item: item)) {
            StudyItemDetailFeature()
        }
        
        await store.send(.deleteButtonTapped) {
            $0.showingDeleteConfirmation = true
        }
    }
    
    func testCancelDelete() async {
        let item = StudyItemState(id: UUID(), title: "Test", content: "Content")
        
        let store = TestStore(initialState: StudyItemDetailFeature.State(
            item: item,
            showingDeleteConfirmation: true
        )) {
            StudyItemDetailFeature()
        }
        
        await store.send(.cancelDelete) {
            $0.showingDeleteConfirmation = false
        }
    }
    
    func testAddTag() async {
        let item = StudyItemState(id: UUID(), title: "Test", content: "Content")
        
        let store = TestStore(initialState: StudyItemDetailFeature.State(
            item: item,
            isEditing: true,
            newTag: "swift"
        )) {
            StudyItemDetailFeature()
        }
        
        await store.send(.addTag) {
            $0.editedTags = ["swift"]
            $0.newTag = ""
        }
    }
    
    func testRemoveTag() async {
        let item = StudyItemState(id: UUID(), title: "Test", content: "Content")
        
        let store = TestStore(initialState: StudyItemDetailFeature.State(
            item: item,
            isEditing: true,
            editedTags: ["swift", "ios"]
        )) {
            StudyItemDetailFeature()
        }
        
        await store.send(.removeTag("swift")) {
            $0.editedTags = ["ios"]
        }
    }
    
    func testImageSelected() async {
        let item = StudyItemState(id: UUID(), title: "Test", content: "Content")
        let imageData = Data([0x00, 0x01, 0x02])
        
        let store = TestStore(initialState: StudyItemDetailFeature.State(
            item: item,
            isEditing: true
        )) {
            StudyItemDetailFeature()
        }
        
        await store.send(.imageSelected(imageData)) {
            $0.editedImagesData = [imageData]
        }
    }
    
    func testRemoveImage() async {
        let item = StudyItemState(id: UUID(), title: "Test", content: "Content")
        let imageData = Data([0x00, 0x01, 0x02])
        
        let store = TestStore(initialState: StudyItemDetailFeature.State(
            item: item,
            isEditing: true,
            editedImagesData: [imageData]
        )) {
            StudyItemDetailFeature()
        }
        
        await store.send(.removeImage(0)) {
            $0.editedImagesData = []
        }
    }
    
    func testPdfSelected() async {
        let item = StudyItemState(id: UUID(), title: "Test", content: "Content")
        let pdfData = Data([0x25, 0x50, 0x44, 0x46])
        
        let store = TestStore(initialState: StudyItemDetailFeature.State(
            item: item,
            isEditing: true
        )) {
            StudyItemDetailFeature()
        }
        
        await store.send(.pdfSelected(pdfData)) {
            $0.editedPdfData = pdfData
        }
    }
    
    func testRemovePDF() async {
        let item = StudyItemState(id: UUID(), title: "Test", content: "Content")
        let pdfData = Data([0x25, 0x50, 0x44, 0x46])
        
        let store = TestStore(initialState: StudyItemDetailFeature.State(
            item: item,
            isEditing: true,
            editedPdfData: pdfData
        )) {
            StudyItemDetailFeature()
        }
        
        await store.send(.removePDF) {
            $0.editedPdfData = nil
        }
    }
}
