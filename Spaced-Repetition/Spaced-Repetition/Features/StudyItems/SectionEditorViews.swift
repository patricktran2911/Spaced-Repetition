//
//  SectionEditorViews.swift
//  Spaced-Repetition
//
//  Section-specific editor views for study items.
//

import SwiftUI
import PhotosUI
import ComposableArchitecture

// MARK: - Content Editor View
struct ContentEditorView: View {
    @Bindable var store: StoreOf<StudyItemDetailFeature>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $store.editedTitle)
                        .font(.headline)
                } header: {
                    Text("Title")
                }
                
                Section {
                    TextField("Content", text: $store.editedContent, axis: .vertical)
                        .lineLimit(10...20)
                } header: {
                    Text("Content")
                } footer: {
                    Text("Describe your lecture content in detail. This will appear on the back of your flashcard.")
                }
            }
            .navigationTitle("Edit Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        store.send(.dismissEditSection)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Images Editor View
struct ImagesEditorView: View {
    @Bindable var store: StoreOf<StudyItemDetailFeature>
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    addImagesButton
                    imagesContent
                }
                .padding()
            }
            .navigationTitle("Images (\(store.editedImagesData.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        store.send(.dismissEditSection)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var addImagesButton: some View {
        PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 10, matching: .images) {
            HStack {
                Image(systemName: "photo.badge.plus")
                    .font(.title2)
                Text("Add Images")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.accentColor.opacity(0.1))
            .foregroundColor(.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
    
    @ViewBuilder
    private var imagesContent: some View {
        if store.editedImagesData.isEmpty {
            ContentUnavailableView {
                Label("No Images", systemImage: "photo.on.rectangle.angled")
            } description: {
                Text("Add images to help visualize your lecture content.")
            }
            .frame(minHeight: 200)
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(store.editedImagesData.enumerated()), id: \.offset) { index, imageData in
                    ImageCard(
                        imageData: imageData,
                        onDelete: { store.send(.removeImage(index)) }
                    )
                }
            }
        }
    }
}

// MARK: - Image Card
private struct ImageCard: View {
    let imageData: Data
    let onDelete: () -> Void
    
    var body: some View {
        if let uiImage = UIImage(data: imageData) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white, .red)
                        .shadow(radius: 2)
                }
                .padding(8)
            }
        }
    }
}

// MARK: - PDFs Editor View
struct PDFsEditorView: View {
    @Bindable var store: StoreOf<StudyItemDetailFeature>
    @Environment(\.dismiss) private var dismiss
    @State private var showingPDFPicker = false
    @State private var showFullScreenPDF = false
    @State private var selectedPDFIndex: Int? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Add PDF Button
                    Button {
                        showingPDFPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                                .font(.title2)
                            Text("Add PDF Document")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // PDF List
                    if store.editedPdfDataArray.isEmpty {
                        ContentUnavailableView {
                            Label("No PDFs", systemImage: "doc.text")
                        } description: {
                            Text("Add PDF documents for your lecture materials.")
                        }
                        .frame(minHeight: 200)
                    } else {
                        ForEach(Array(store.editedPdfDataArray.enumerated()), id: \.offset) { index, pdfData in
                            PDFDocumentCard(
                                pdfData: pdfData,
                                index: index,
                                onTap: {
                                    selectedPDFIndex = index
                                    showFullScreenPDF = true
                                },
                                onDelete: { store.send(.removePDF(index)) }
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("PDFs (\(store.editedPdfDataArray.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        store.send(.dismissEditSection)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .fileImporter(
                isPresented: $showingPDFPicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    for url in urls {
                        if url.startAccessingSecurityScopedResource() {
                            defer { url.stopAccessingSecurityScopedResource() }
                            if let data = try? Data(contentsOf: url) {
                                store.send(.pdfSelected(data))
                            }
                        }
                    }
                case .failure:
                    break
                }
            }
            .fullScreenCover(isPresented: $showFullScreenPDF) {
                if let index = selectedPDFIndex, index < store.editedPdfDataArray.count {
                    FullScreenPDFViewer(pdfData: store.editedPdfDataArray[index])
                }
            }
        }
    }
}

// MARK: - PDF Document Card
private struct PDFDocumentCard: View {
    let pdfData: Data
    let index: Int
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // PDF Preview
            PDFThumbnailView(pdfData: pdfData)
                .frame(width: 60, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Document \(index + 1)")
                    .font(.headline)
                
                if let pageCount = getPDFPageCount(pdfData) {
                    Text("\(pageCount) page\(pageCount == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 16) {
                Button(action: onTap) {
                    Image(systemName: "eye")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
    
    private func getPDFPageCount(_ data: Data) -> Int? {
        guard let provider = CGDataProvider(data: data as CFData),
              let pdfDocument = CGPDFDocument(provider) else { return nil }
        return pdfDocument.numberOfPages
    }
}

// MARK: - PDF Thumbnail View
private struct PDFThumbnailView: View {
    let pdfData: Data
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .onAppear { loadThumbnail() }
    }
    
    private func loadThumbnail() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let provider = CGDataProvider(data: pdfData as CFData),
                  let pdfDocument = CGPDFDocument(provider),
                  let page = pdfDocument.page(at: 1) else { return }
            
            let pageRect = page.getBoxRect(.mediaBox)
            let scale: CGFloat = 120 / pageRect.width
            let scaledSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
            
            let renderer = UIGraphicsImageRenderer(size: scaledSize)
            let image = renderer.image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: scaledSize))
                
                context.cgContext.translateBy(x: 0, y: scaledSize.height)
                context.cgContext.scaleBy(x: scale, y: -scale)
                context.cgContext.drawPDFPage(page)
            }
            
            DispatchQueue.main.async {
                thumbnail = image
            }
        }
    }
}

// MARK: - URLs Editor View
struct URLsEditorView: View {
    @Bindable var store: StoreOf<StudyItemDetailFeature>
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isUrlFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Add URL Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add URL")
                            .font(.headline)
                        
                        HStack {
                            TextField("https://example.com", text: $store.newUrlString)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.URL)
                                .textContentType(.URL)
                                .autocapitalization(.none)
                                .focused($isUrlFieldFocused)
                                .onSubmit { store.send(.addUrl) }
                            
                            Button {
                                store.send(.addUrl)
                                isUrlFieldFocused = false
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                            .disabled(store.newUrlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // URL List
                    if store.editedUrls.isEmpty {
                        ContentUnavailableView {
                            Label("No URLs", systemImage: "link")
                        } description: {
                            Text("Add reference URLs for your lecture materials.")
                        }
                        .frame(minHeight: 200)
                    } else {
                        ForEach(Array(store.editedUrls.enumerated()), id: \.offset) { index, url in
                            URLCard(
                                url: url,
                                onDelete: { store.send(.removeUrl(index)) }
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("URLs (\(store.editedUrls.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        store.send(.dismissEditSection)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - URL Card
private struct URLCard: View {
    let url: URL
    let onDelete: () -> Void
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "link")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(url.host ?? url.absoluteString)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(url.absoluteString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button {
                    openURL(url)
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Tags Editor View
struct TagsEditorView: View {
    @Bindable var store: StoreOf<StudyItemDetailFeature>
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTagFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Add Tag Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Tag")
                            .font(.headline)
                        
                        HStack {
                            TextField("Enter tag name", text: $store.newTag)
                                .textFieldStyle(.roundedBorder)
                                .focused($isTagFieldFocused)
                                .onSubmit { store.send(.addTag) }
                            
                            Button {
                                store.send(.addTag)
                                isTagFieldFocused = false
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                            .disabled(store.newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Tags Grid
                    if store.editedTags.isEmpty {
                        ContentUnavailableView {
                            Label("No Tags", systemImage: "tag")
                        } description: {
                            Text("Add tags to organize your lectures.")
                        }
                        .frame(minHeight: 200)
                    } else {
                        FlowLayout(spacing: 10) {
                            ForEach(store.editedTags, id: \.self) { tag in
                                TagChip(
                                    tag: tag,
                                    onDelete: { store.send(.removeTag(tag)) }
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Tags (\(store.editedTags.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        store.send(.dismissEditSection)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Tag Chip
private struct TagChip: View {
    let tag: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(tag)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.accentColor.opacity(0.15))
        .foregroundStyle(Color.accentColor)
        .clipShape(Capsule())
    }
}
