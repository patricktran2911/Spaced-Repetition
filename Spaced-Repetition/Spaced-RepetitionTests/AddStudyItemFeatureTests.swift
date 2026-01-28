//
//  AddStudyItemFeatureTests.swift
//  Spaced-RepetitionTests
//

import ComposableArchitecture
import XCTest
@testable import Spaced_Repetition

@MainActor
final class AddStudyItemFeatureTests: XCTestCase {
    
    func testIsValidWithEmptyTitle() {
        let state = AddStudyItemFeature.State(title: "", content: "Content")
        XCTAssertFalse(state.isValid)
    }
    
    func testIsValidWithEmptyContent() {
        let state = AddStudyItemFeature.State(title: "Title", content: "")
        XCTAssertFalse(state.isValid)
    }
    
    func testIsValidWithWhitespaceOnly() {
        let state = AddStudyItemFeature.State(title: "   ", content: "   ")
        XCTAssertFalse(state.isValid)
    }
    
    func testIsValidWithValidInput() {
        let state = AddStudyItemFeature.State(title: "Title", content: "Content")
        XCTAssertTrue(state.isValid)
    }
    
    func testSaveButtonTappedWithInvalidInput() async {
        let store = TestStore(initialState: AddStudyItemFeature.State(title: "", content: "")) {
            AddStudyItemFeature()
        }
        
        await store.send(.saveButtonTapped)
    }
    
    func testCancelButtonTapped() async {
        let store = TestStore(initialState: AddStudyItemFeature.State()) {
            AddStudyItemFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect { }
        }
        
        await store.send(.cancelButtonTapped)
    }
    
    func testAddTag() async {
        let store = TestStore(initialState: AddStudyItemFeature.State(newTag: "swift")) {
            AddStudyItemFeature()
        }
        
        await store.send(.addTag) {
            $0.tags = ["swift"]
            $0.newTag = ""
        }
    }
    
    func testAddTagWithEmptyString() async {
        let store = TestStore(initialState: AddStudyItemFeature.State(newTag: "")) {
            AddStudyItemFeature()
        }
        
        await store.send(.addTag)
    }
    
    func testAddDuplicateTag() async {
        let store = TestStore(initialState: AddStudyItemFeature.State(
            tags: ["swift"],
            newTag: "swift"
        )) {
            AddStudyItemFeature()
        }
        
        await store.send(.addTag)
    }
    
    func testRemoveTag() async {
        let store = TestStore(initialState: AddStudyItemFeature.State(tags: ["swift", "ios"])) {
            AddStudyItemFeature()
        }
        
        await store.send(.removeTag("swift")) {
            $0.tags = ["ios"]
        }
    }
    
    func testImageSelected() async {
        let imageData = Data([0x00, 0x01, 0x02])
        
        let store = TestStore(initialState: AddStudyItemFeature.State()) {
            AddStudyItemFeature()
        }
        
        await store.send(.imageSelected(imageData)) {
            $0.imagesData = [imageData]
        }
    }
    
    func testRemoveImage() async {
        let imageData = Data([0x00, 0x01, 0x02])
        
        let store = TestStore(initialState: AddStudyItemFeature.State(imagesData: [imageData])) {
            AddStudyItemFeature()
        }
        
        await store.send(.removeImage(0)) {
            $0.imagesData = []
        }
    }
    
    func testPdfSelected() async {
        let pdfData = Data([0x25, 0x50, 0x44, 0x46])
        
        let store = TestStore(initialState: AddStudyItemFeature.State()) {
            AddStudyItemFeature()
        }
        
        await store.send(.pdfSelected(pdfData)) {
            $0.pdfData = pdfData
        }
    }
    
    func testRemovePDF() async {
        let pdfData = Data([0x25, 0x50, 0x44, 0x46])
        
        let store = TestStore(initialState: AddStudyItemFeature.State(pdfData: pdfData)) {
            AddStudyItemFeature()
        }
        
        await store.send(.removePDF) {
            $0.pdfData = nil
        }
    }
    
    func testHasMedia() {
        let stateWithImages = AddStudyItemFeature.State(imagesData: [Data()])
        XCTAssertTrue(stateWithImages.hasMedia)
        
        let stateWithPDF = AddStudyItemFeature.State(pdfData: Data())
        XCTAssertTrue(stateWithPDF.hasMedia)
        
        let stateWithoutMedia = AddStudyItemFeature.State()
        XCTAssertFalse(stateWithoutMedia.hasMedia)
    }
}
