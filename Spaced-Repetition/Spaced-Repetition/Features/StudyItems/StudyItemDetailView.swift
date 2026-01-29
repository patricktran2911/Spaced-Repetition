//
//  StudyItemDetailView.swift
//  Spaced-Repetition
//
//  Created by Patrick Tran on 1/20/26.
//

import SwiftUI
import ComposableArchitecture
import PhotosUI
import UniformTypeIdentifiers

struct StudyItemDetailView: View {
    @Bindable var store: StoreOf<StudyItemDetailFeature>
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showingPDFPicker = false
    @State private var showFullScreenPDF = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ReviewStatusCard(
                    item: store.item,
                    isEditing: store.isEditing,
                    onStartReview: { store.send(.startReviewTapped) }
                )
                
                if store.isEditing {
                    ItemEditingView(
                        store: store,
                        selectedPhotoItems: $selectedPhotoItems,
                        onShowPDFPicker: { showingPDFPicker = true }
                    )
                }
            }
            .padding()
            .frame(maxWidth: horizontalSizeClass == .regular ? 800 : .infinity)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(store.isEditing ? "Edit Item" : store.item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if store.isEditing {
                    Button("Save") {
                        store.send(.saveEditTapped)
                    }
                    .disabled(store.isSaving)
                } else {
                    Menu {
                        Button {
                            store.send(.editButtonTapped)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            store.send(.deleteButtonTapped)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            
            if store.isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.send(.cancelEditTapped)
                    }
                }
            }
        }
        .alert("Delete Item?", isPresented: $store.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                store.send(.cancelDelete)
            }
            Button("Delete", role: .destructive) {
                store.send(.confirmDelete)
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(item: $store.scope(state: \.reviewSession, action: \.reviewSession)) { store in
            NavigationStack {
                ReviewView(store: store)
            }
        }
        .fileImporter(
            isPresented: $showingPDFPicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handlePDFImport(result)
        }
        .fullScreenCover(isPresented: $showFullScreenPDF) {
            if let pdfData = store.item.pdfData {
                NavigationStack {
                    PDFPageView(pdfData: pdfData)
                        .navigationTitle("PDF Document")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showFullScreenPDF = false
                                }
                            }
                        }
                }
            }
        }
        .disabled(store.isSaving)
        .overlay {
            if store.isSaving {
                SavingOverlay(message: "Saving...")
            }
        }
    }
    
    private func handlePDFImport(_ result: Result<[URL], Error>) {
        if case .success(let urls) = result, let url = urls.first {
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            if let data = try? Data(contentsOf: url) {
                store.send(.pdfSelected(data))
            }
        }
    }
}
