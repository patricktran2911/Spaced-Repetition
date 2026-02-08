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
    @FocusState private var focusedField: AddStudyItemField?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
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
            Section {
                pdfSection
            } header: {
                HStack {
                    Text("PDF Documents")
                    Spacer()
                    if !store.pdfDataArray.isEmpty {
                        Text("\(store.pdfDataArray.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // URLs Section
            Section {
                urlsSection
            } header: {
                HStack {
                    Text("Reference URLs")
                    Spacer()
                    if !store.urls.isEmpty {
                        Text("\(store.urls.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
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
            isPresented: $store.showingPDFPicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            handlePDFImport(result)
        }
        .onChange(of: focusedField) { _, newValue in
            store.send(.focusedFieldChanged(newValue))
        }
        .onChange(of: store.focusedField) { _, newValue in
            focusedField = newValue
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
                selection: $store.selectedPhotoItems,
                maxSelectionCount: 10,
                matching: .images
            ) {
                Label("Add Images", systemImage: "photo.on.rectangle.angled")
            }
            .onChange(of: store.selectedPhotoItems) { _, newItems in
                store.send(.photoItemsChanged(newItems))
            }
        }
    }
    
    // MARK: - PDF Section
    private var pdfSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // PDF list
            if !store.pdfDataArray.isEmpty {
                ForEach(Array(store.pdfDataArray.enumerated()), id: \.offset) { index, pdfData in
                    HStack {
                        PDFPreviewCard(pdfData: pdfData)
                        
                        Spacer()
                        
                        Button {
                            store.send(.removePDF(index))
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            // Add PDF button
            Button {
                store.send(.binding(.set(\.showingPDFPicker, true)))
            } label: {
                Label("Add PDF", systemImage: "doc.badge.plus")
            }
        }
    }
    
    // MARK: - URLs Section
    private var urlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // URL list
            if !store.urls.isEmpty {
                ForEach(Array(store.urls.enumerated()), id: \.offset) { index, url in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(url.host ?? url.absoluteString)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            
                            Text(url.absoluteString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Button {
                            store.send(.removeUrl(index))
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            // Add URL input
            HStack {
                TextField("Enter URL (e.g., example.com)", text: $store.newUrlString)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .onSubmit {
                        store.send(.addUrl)
                    }
                
                Button {
                    store.send(.addUrl)
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(store.newUrlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
            for url in urls {
                // Start accessing security-scoped resource
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }
                
                if let data = try? Data(contentsOf: url) {
                    store.send(.pdfSelected(data))
                }
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
