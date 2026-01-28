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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                reviewStatusCard
                
                if store.isEditing {
                    editingView
                } else {
                    displayView
                }
            }
            .padding()
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
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("Saving...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    // MARK: - Review Status Card
    private var reviewStatusCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if store.item.isDue {
                        Label("Due Now", systemImage: "bell.badge.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                    } else {
                        Label("Next Review", systemImage: "calendar")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("in \(store.item.daysUntilReview) days")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Reviews")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(store.item.reviewCount)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            
            Divider()
            
            HStack {
                StatItem(title: "Interval", value: "\(store.item.interval)d")
                Spacer()
                StatItem(title: "Ease", value: String(format: "%.1f", store.item.easeFactor))
                Spacer()
                StatItem(title: "Created", value: store.item.createdAt.formatted(date: .abbreviated, time: .omitted))
            }
            
            Button {
                store.send(.startReviewTapped)
            } label: {
                Label("Start Review", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.isEditing)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Display View
    private var displayView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(store.item.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(store.item.content)
                .font(.body)
            
            // Images Gallery
            if !store.item.allImages.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Images (\(store.item.allImages.count))")
                        .font(.headline)
                    
                    ImageGalleryView(images: store.item.allImages)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // PDF Document
            if let pdfData = store.item.pdfData {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PDF Document")
                        .font(.headline)
                    
                    Button {
                        showFullScreenPDF = true
                    } label: {
                        PDFPreviewCard(pdfData: pdfData)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Tags
            if !store.item.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.headline)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(store.item.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.accentColor.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Editing View
    private var editingView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Title").font(.headline)
                TextField("Title", text: $store.editedTitle)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Content").font(.headline)
                TextField("Content", text: $store.editedContent, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(5...10)
            }
            
            // Images
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Images").font(.headline)
                    Spacer()
                    Text("\(store.editedImagesData.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if !store.editedImagesData.isEmpty {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(Array(store.editedImagesData.enumerated()), id: \.offset) { index, imageData in
                            if let uiImage = UIImage(data: imageData) {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    Button { store.send(.removeImage(index)) } label: {
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
                
                PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 10, matching: .images) {
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
            
            // PDF
            VStack(alignment: .leading, spacing: 8) {
                Text("PDF Document").font(.headline)
                
                if let pdfData = store.editedPdfData {
                    PDFPreviewCard(pdfData: pdfData)
                    Button("Remove PDF", role: .destructive) { store.send(.removePDF) }
                } else {
                    Button { showingPDFPicker = true } label: {
                        Label("Import PDF", systemImage: "doc.badge.plus")
                    }
                }
            }
            
            // Tags
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags").font(.headline)
                
                if !store.editedTags.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(store.editedTags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag).font(.caption)
                                Button { store.send(.removeTag(tag)) } label: {
                                    Image(systemName: "xmark.circle.fill").font(.caption)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.2))
                            .clipShape(Capsule())
                        }
                    }
                }
                
                HStack {
                    TextField("Add tag", text: $store.newTag)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { store.send(.addTag) }
                    
                    Button { store.send(.addTag) } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(store.newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
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

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline).fontWeight(.medium)
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
