//
//  AddStudyItemFeature.swift
//  Spaced-Repetition
//
//  Created by Patrick Tran on 1/20/26.
//

import Foundation
import ComposableArchitecture
import PhotosUI
import SwiftUI

enum AddStudyItemField: Equatable, Sendable, Hashable {
    case title, content, tag
}

@Reducer
struct AddStudyItemFeature {
    @ObservableState
    struct State: Equatable {
        var title: String = ""
        var content: String = ""
        var imagesData: [Data] = []
        var pdfDataArray: [Data] = []  // Multiple PDFs
        var urls: [URL] = []  // Multiple URLs
        var newUrlString: String = ""  // For adding new URLs
        var tags: [String] = []
        var newTag: String = ""
        var isSaving: Bool = false
        var selectedPhotoItems: [PhotosPickerItem] = []
        var showingPDFPicker: Bool = false
        var focusedField: AddStudyItemField?
        
        // Legacy compatibility
        var pdfData: Data? {
            get { pdfDataArray.first }
            set {
                if let data = newValue {
                    if pdfDataArray.isEmpty {
                        pdfDataArray = [data]
                    } else {
                        pdfDataArray[0] = data
                    }
                } else {
                    if !pdfDataArray.isEmpty {
                        pdfDataArray.removeFirst()
                    }
                }
            }
        }
        
        var isValid: Bool {
            !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        var hasMedia: Bool {
            !imagesData.isEmpty || !pdfDataArray.isEmpty || !urls.isEmpty
        }
        
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case saveButtonTapped
        case cancelButtonTapped
        case addTag
        case removeTag(String)
        case imageSelected(Data)
        case removeImage(Int)
        case pdfSelected(Data)
        case removePDF(Int)
        case addUrl
        case removeUrl(Int)
        case photoItemsChanged([PhotosPickerItem])
        case focusedFieldChanged(AddStudyItemField?)
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate: Equatable {
            case itemSaved
        }
    }
    
    @Dependency(\.databaseClient) var databaseClient
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .saveButtonTapped:
                guard state.isValid else { return .none }
                state.isSaving = true
                
                // Set first review for tomorrow (not immediately)
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
                
                // Extract all values before the async closure
                let id = UUID()
                let title = state.title.trimmingCharacters(in: .whitespacesAndNewlines)
                let content = state.content.trimmingCharacters(in: .whitespacesAndNewlines)
                let imagesData = state.imagesData
                let pdfDataArray = state.pdfDataArray
                let urls = state.urls
                let tags = state.tags
                let createdAt = now
                let nextReviewDate = tomorrow
                
                return .run { send in
                    let item = await StudyItemState(
                        id: id,
                        title: title,
                        content: content,
                        imagesData: imagesData,
                        pdfDataArray: pdfDataArray,
                        urls: urls,
                        createdAt: createdAt,
                        nextReviewDate: nextReviewDate,
                        reviewCount: 0,
                        easeFactor: 2.5,
                        interval: 1,
                        tags: tags
                    )
                    try await databaseClient.saveStudyItem(item)
                    await send(.delegate(.itemSaved))
                }
                
            case .cancelButtonTapped:
                return .run { _ in
                    await dismiss()
                }
                
            case .addTag:
                let tag = state.newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !tag.isEmpty, !state.tags.contains(tag) else { return .none }
                state.tags.append(tag)
                state.newTag = ""
                return .none
                
            case let .removeTag(tag):
                state.tags.removeAll { $0 == tag }
                return .none
                
            case let .imageSelected(data):
                state.imagesData.append(data)
                return .none
                
            case let .removeImage(index):
                guard index < state.imagesData.count else { return .none }
                state.imagesData.remove(at: index)
                return .none
                
            case let .pdfSelected(data):
                state.pdfDataArray.append(data)
                return .none
                
            case let .removePDF(index):
                guard index < state.pdfDataArray.count else { return .none }
                state.pdfDataArray.remove(at: index)
                return .none
                
            case .addUrl:
                let urlString = state.newUrlString.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !urlString.isEmpty else { return .none }
                
                // Add https:// if no scheme is provided
                var finalUrlString = urlString
                if !urlString.lowercased().hasPrefix("http://") && !urlString.lowercased().hasPrefix("https://") {
                    finalUrlString = "https://" + urlString
                }
                
                guard let url = URL(string: finalUrlString),
                      !state.urls.contains(url) else { return .none }
                state.urls.append(url)
                state.newUrlString = ""
                return .none
                
            case let .removeUrl(index):
                guard index < state.urls.count else { return .none }
                state.urls.remove(at: index)
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
                
            case let .focusedFieldChanged(field):
                state.focusedField = field
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}
