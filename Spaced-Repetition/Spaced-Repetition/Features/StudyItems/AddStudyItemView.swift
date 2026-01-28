//
//  AddStudyItemView.swift
//  Spaced-Repetition
//
//  Created by Patrick Tran on 1/20/26.
//

import SwiftUI
import ComposableArchitecture
import PhotosUI
import UniformTypeIdentifiers

struct AddStudyItemView: View {
    @Bindable var store: StoreOf<AddStudyItemFeature>
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showingPDFPicker = false
    @FocusState private var focusedField: Field?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    enum Field {
        case title, content, tag
    }
    
    var body: some View {
        Form {
            Section("Details") {
                TextField("Title (Question)", text: $store.title)
                    .focused($focusedField, equals: .title)
                
                TextField("Content (Answer)", text: $store.content, axis: .vertical)
                    .lineLimit(5...10)
                    .focused($focusedField, equals: .content)
            }
            
            // Images Section
            Section {
                imagesSection
            } header: {
                HStack {
                    Text("Images")
                    Spacer()
                    if !store.imagesData.isEmpty {
                        Text("\(store.imagesData.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // PDF Section
            Section("PDF Document") {
                pdfSection
            }
            
            // Tags Section
            Section("Tags") {
                tagsSection
            }
        }
        .frame(maxWidth: horizontalSizeClass == .regular ? 700 : .infinity)
        .frame(maxWidth: .infinity)
        .scrollContentBackground(horizontalSizeClass == .regular ? .hidden : .automatic)
        .background(horizontalSizeClass == .regular ? Color(.systemGroupedBackground) : Color.clear)
        .navigationTitle("New Study Item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    store.send(.cancelButtonTapped)
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    store.send(.saveButtonTapped)
                }
                .disabled(!store.isValid || store.isSaving)
            }
        }
        .disabled(store.isSaving)
        .overlay {
            if store.isSaving {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("Saving...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .fileImporter(
            isPresented: $showingPDFPicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handlePDFImport(result)
        }
    }
    
    // MARK: - Images Section
    private var imagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image grid
            if !store.imagesData.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(Array(store.imagesData.enumerated()), id: \.offset) { index, imageData in
                        if let uiImage = UIImage(data: imageData) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                Button {
                                    store.send(.removeImage(index))
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white, .red)
                                        .font(.title3)
                                }
                                .offset(x: 5, y: -5)
                            }
                        }
                    }
                }
            }
            
            // Add images button
            PhotosPicker(
                selection: $selectedPhotoItems,
                maxSelectionCount: 10,
                matching: .images
            ) {
                Label("Add Images", systemImage: "photo.on.rectangle.angled")
            }
            .onChange(of: selectedPhotoItems) { _, newItems in
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            store.send(.imageSelected(data))
                        }
                    }
                    selectedPhotoItems = []
                }
            }
        }
    }
    
    // MARK: - PDF Section
    private var pdfSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let pdfData = store.pdfData {
                PDFPreviewCard(pdfData: pdfData)
                
                Button("Remove PDF", role: .destructive) {
                    store.send(.removePDF)
                }
            } else {
                Button {
                    showingPDFPicker = true
                } label: {
                    Label("Import PDF", systemImage: "doc.badge.plus")
                }
            }
        }
    }
    
    // MARK: - Tags Section
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !store.tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(store.tags, id: \.self) { tag in
                        TagView(tag: tag) {
                            store.send(.removeTag(tag))
                        }
                    }
                }
            }
            
            HStack {
                TextField("Add tag", text: $store.newTag)
                    .focused($focusedField, equals: .tag)
                    .onSubmit {
                        store.send(.addTag)
                    }
                
                Button {
                    store.send(.addTag)
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(store.newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    // MARK: - PDF Import Handler
    private func handlePDFImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            if let data = try? Data(contentsOf: url) {
                store.send(.pdfSelected(data))
            }
            
        case .failure(let error):
            print("PDF import failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Tag View
struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.2))
        .foregroundStyle(.primary)
        .clipShape(Capsule())
    }
}
#Preview {
    NavigationStack {
        AddStudyItemView(
            store: Store(initialState: AddStudyItemFeature.State()) {
                AddStudyItemFeature()
            }
        )
    }
}
