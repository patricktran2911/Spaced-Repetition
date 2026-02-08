//
//  StudyItemDetailFeature.swift
//  Spaced-Repetition
//
//  Created by Patrick Tran on 1/20/26.
//

import Foundation
import ComposableArchitecture
import PhotosUI
import SwiftUI

@Reducer
struct StudyItemDetailFeature {
    @ObservableState
    struct State: Equatable {
        var item: StudyItemState
        var isEditing: Bool = false
        var editedTitle: String = ""
        var editedContent: String = ""
        var editedTags: [String] = []
        var newTag: String = ""
        var editedImagesData: [Data] = []
        var editedPdfDataArray: [Data] = []  // Multiple PDFs
        var editedUrls: [URL] = []  // Multiple URLs
        var newUrlString: String = ""  // For adding new URLs
        var isSaving: Bool = false
        var showingDeleteConfirmation: Bool = false
        var selectedPhotoItems: [PhotosPickerItem] = []
        var showingPDFPicker: Bool = false
        var showFullScreenPDF: Bool = false
        var showFullScreenPDFIndex: Int? = nil  // Track which PDF to show
        @Presents var reviewSession: ReviewFeature.State?
        
        // Section editing navigation
        enum EditSection: Equatable, Hashable {
            case content
            case images
            case pdfs
            case urls
            case tags
        }
        var activeEditSection: EditSection? = nil
        
        // Legacy compatibility
        var editedPdfData: Data? {
            get { editedPdfDataArray.first }
            set {
                if let data = newValue {
                    if editedPdfDataArray.isEmpty {
                        editedPdfDataArray = [data]
                    } else {
                        editedPdfDataArray[0] = data
                    }
                } else {
                    if !editedPdfDataArray.isEmpty {
                        editedPdfDataArray.removeFirst()
                    }
                }
            }
        }
        
        static func == (lhs: State, rhs: State) -> Bool {
            lhs.item == rhs.item &&
            lhs.isEditing == rhs.isEditing &&
            lhs.editedTitle == rhs.editedTitle &&
            lhs.editedContent == rhs.editedContent &&
            lhs.editedTags == rhs.editedTags &&
            lhs.newTag == rhs.newTag &&
            lhs.editedImagesData == rhs.editedImagesData &&
            lhs.editedPdfDataArray == rhs.editedPdfDataArray &&
            lhs.editedUrls == rhs.editedUrls &&
            lhs.newUrlString == rhs.newUrlString &&
            lhs.isSaving == rhs.isSaving &&
            lhs.showingDeleteConfirmation == rhs.showingDeleteConfirmation &&
            lhs.showingPDFPicker == rhs.showingPDFPicker &&
            lhs.showFullScreenPDF == rhs.showFullScreenPDF &&
            lhs.showFullScreenPDFIndex == rhs.showFullScreenPDFIndex &&
            lhs.reviewSession == rhs.reviewSession &&
            lhs.activeEditSection == rhs.activeEditSection
        }
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case editButtonTapped
        case cancelEditTapped
        case saveEditTapped
        case deleteButtonTapped
        case confirmDelete
        case cancelDelete
        case startReviewTapped
        case addTag
        case removeTag(String)
        case imageSelected(Data)
        case removeImage(Int)
        case pdfSelected(Data)
        case removePDF(Int)
        case addUrl
        case removeUrl(Int)
        case photoItemsChanged([PhotosPickerItem])
        case reviewCompletedFetchedItem(StudyItemState?)
        case reviewSession(PresentationAction<ReviewFeature.Action>)
        case editSectionTapped(State.EditSection?)
        case dismissEditSection
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case itemUpdated
            case itemDeleted
        }
    }
    
    @Dependency(\.databaseClient) var databaseClient
    @Dependency(\.dismiss) var dismiss
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .editButtonTapped:
                state.isEditing = true
                state.editedTitle = state.item.title
                state.editedContent = state.item.content
                state.editedTags = state.item.tags
                state.editedImagesData = state.item.imagesData
                state.editedPdfDataArray = state.item.allPDFs
                state.editedUrls = state.item.allURLs
                return .none
                
            case .cancelEditTapped:
                state.isEditing = false
                return .run { _ in
                    await dismiss()
                }
                
            case .saveEditTapped:
                guard !state.editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      !state.editedContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    return .none
                }
                
                state.isSaving = true
                
                // Create updated item with new values
                var updatedItem = state.item
                updatedItem.title = state.editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                updatedItem.content = state.editedContent.trimmingCharacters(in: .whitespacesAndNewlines)
                updatedItem.tags = state.editedTags
                updatedItem.imagesData = state.editedImagesData
                updatedItem.pdfDataArray = state.editedPdfDataArray
                updatedItem.urls = state.editedUrls
                
                // Update local state immediately
                state.item = updatedItem
                
                // Extract all values BEFORE the async closure
                let id = updatedItem.id
                let title = updatedItem.title
                let content = updatedItem.content
                let imageData = updatedItem.imageData
                let imagesData = updatedItem.imagesData
                let pdfData = updatedItem.pdfData
                let pdfDataArray = updatedItem.pdfDataArray
                let pdfURL = updatedItem.pdfURL
                let url = updatedItem.url
                let urls = updatedItem.urls
                let nextReviewDate = updatedItem.nextReviewDate
                let reviewCount = updatedItem.reviewCount
                let easeFactor = updatedItem.easeFactor
                let interval = updatedItem.interval
                let tags = updatedItem.tags
                
                return .run { send in
                    let itemToSave = await StudyItemState(
                        id: id,
                        title: title,
                        content: content,
                        imageData: imageData,
                        imagesData: imagesData,
                        pdfData: pdfData,
                        pdfDataArray: pdfDataArray,
                        pdfURL: pdfURL,
                        url: url,
                        urls: urls,
                        nextReviewDate: nextReviewDate,
                        reviewCount: reviewCount,
                        easeFactor: easeFactor,
                        interval: interval,
                        tags: tags
                    )
                    try await databaseClient.updateStudyItem(itemToSave)
                    await send(.delegate(.itemUpdated))
                }
                
            case .deleteButtonTapped:
                state.showingDeleteConfirmation = true
                return .none
                
            case .confirmDelete:
                let itemId = state.item.id
                return .run { send in
                    try await databaseClient.deleteStudyItem(itemId)
                    await send(.delegate(.itemDeleted))
                }
                
            case .cancelDelete:
                state.showingDeleteConfirmation = false
                return .none
                
            case .startReviewTapped:
                state.reviewSession = ReviewFeature.State(item: state.item)
                return .none
                
            case .addTag:
                let tag = state.newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !tag.isEmpty, !state.editedTags.contains(tag) else { return .none }
                state.editedTags.append(tag)
                state.newTag = ""
                return .none
                
            case let .removeTag(tag):
                state.editedTags.removeAll { $0 == tag }
                return .none
                
            case let .imageSelected(data):
                state.editedImagesData.append(data)
                return .none
                
            case let .removeImage(index):
                guard index < state.editedImagesData.count else { return .none }
                state.editedImagesData.remove(at: index)
                return .none
                
            case let .pdfSelected(data):
                state.editedPdfDataArray.append(data)
                return .none
                
            case let .removePDF(index):
                guard index < state.editedPdfDataArray.count else { return .none }
                state.editedPdfDataArray.remove(at: index)
                return .none
                
            case .addUrl:
                let urlString = state.newUrlString.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !urlString.isEmpty,
                      let url = URL(string: urlString),
                      !state.editedUrls.contains(url) else { return .none }
                state.editedUrls.append(url)
                state.newUrlString = ""
                return .none
                
            case let .removeUrl(index):
                guard index < state.editedUrls.count else { return .none }
                state.editedUrls.remove(at: index)
                return .none
                
            case let .photoItemsChanged(items):
                state.selectedPhotoItems = items
                return .run { send in
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            await send(.imageSelected(data))
                        }
                    }
                }
                
            case let .editSectionTapped(section):
                state.activeEditSection = section
                return .none
                
            case .dismissEditSection:
                state.activeEditSection = nil
                return .none
                
            case .reviewSession(.presented(.delegate(.reviewCompleted))):
                state.reviewSession = nil
                let currentItem = state.item
                return .run { send in
                    let fetched = try await databaseClient.fetchStudyItem(currentItem.id)
                    await send(.reviewCompletedFetchedItem(fetched))
                }
                
            case .reviewSession:
                return .none
                
            case let .reviewCompletedFetchedItem(fetched):
                if let fetched {
                    state.item = fetched
                }
                return .run { send in
                    await send(.delegate(.itemUpdated))
                }
                
            case .delegate(.itemUpdated):
                state.isEditing = false
                state.isSaving = false
                return .none
                
            case .delegate(.itemDeleted):
                return .run { _ in
                    await dismiss()
                }
            }
        }
        .ifLet(\.$reviewSession, action: \.reviewSession) {
            ReviewFeature()
        }
    }
}
