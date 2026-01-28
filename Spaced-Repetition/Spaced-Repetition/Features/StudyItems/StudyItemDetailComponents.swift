//
//  StudyItemDetailComponents.swift
//  Spaced-Repetition
//
//  Components for the Study Item Detail view.
//

import SwiftUI
import PhotosUI
import ComposableArchitecture

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Review Status Card
struct ReviewStatusCard: View {
    let item: StudyItemState
    let isEditing: Bool
    let onStartReview: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if item.isDue {
                        Label("Due Now", systemImage: "bell.badge.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                    } else {
                        Label("Next Review", systemImage: "calendar")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("in \(item.daysUntilReview) days")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Reviews")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(item.reviewCount)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            
            Divider()
            
            HStack {
                StatItem(title: "Interval", value: "\(item.interval)d")
                Spacer()
                StatItem(title: "Ease", value: String(format: "%.1f", item.easeFactor))
                Spacer()
                StatItem(title: "Created", value: item.createdAt.formatted(date: .abbreviated, time: .omitted))
            }
            
            Button(action: onStartReview) {
                Label("Start Review", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isEditing)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Item Display View
struct ItemDisplayView: View {
    let item: StudyItemState
    let onShowPDF: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(item.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(item.content)
                .font(.body)
            
            // Images Gallery
            if !item.allImages.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Images (\(item.allImages.count))")
                        .font(.headline)
                    
                    ImageGalleryView(images: item.allImages)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // PDF Document
            if let pdfData = item.pdfData {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PDF Document")
                        .font(.headline)
                    
                    Button(action: onShowPDF) {
                        PDFPreviewCard(pdfData: pdfData)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Tags
            if !item.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.headline)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(item.tags, id: \.self) { tag in
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
}

// MARK: - Item Editing View
struct ItemEditingView: View {
    @Bindable var store: StoreOf<StudyItemDetailFeature>
    @Binding var selectedPhotoItems: [PhotosPickerItem]
    let onShowPDFPicker: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Title").font(.headline)
                TextField("Title", text: $store.editedTitle)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Content
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
                    Button(action: onShowPDFPicker) {
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
}
