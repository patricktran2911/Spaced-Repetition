//
//  AddStudyItemFeature.swift
//  Spaced-Repetition
//
//  Created by Patrick Tran on 1/20/26.
//

import Foundation
import ComposableArchitecture

@Reducer
struct AddStudyItemFeature {
    @ObservableState
    struct State: Equatable {
        var title: String = ""
        var content: String = ""
        var imagesData: [Data] = []
        var pdfData: Data?
        var tags: [String] = []
        var newTag: String = ""
        var isSaving: Bool = false
        
        var isValid: Bool {
            !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        var hasMedia: Bool {
            !imagesData.isEmpty || pdfData != nil
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
        case removePDF
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
                let pdfData = state.pdfData
                let tags = state.tags
                let createdAt = now
                let nextReviewDate = tomorrow
                
                return .run { send in
                    let item = StudyItemState(
                        id: id,
                        title: title,
                        content: content,
                        imagesData: imagesData,
                        pdfData: pdfData,
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
                state.pdfData = data
                return .none
                
            case .removePDF:
                state.pdfData = nil
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}