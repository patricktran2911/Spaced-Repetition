//
//  PDFPageView.swift
//  Spaced-Repetition
//
//  PDF viewer with page navigation for review
//

import SwiftUI
import PDFKit

// MARK: - PDF Page View
struct PDFPageView: View {
    let pdfData: Data
    @State private var currentPage: Int = 0
    @State private var totalPages: Int = 1
    @State private var pdfDocument: PDFDocument?
    
    var body: some View {
        VStack(spacing: 0) {
            // PDF Content
            if let document = pdfDocument {
                PDFPageRenderer(document: document, pageIndex: currentPage)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
                    .gesture(
                        DragGesture(minimumDistance: 50)
                            .onEnded { value in
                                if value.translation.width < -50 {
                                    // Swipe left - next page
                                    nextPage()
                                } else if value.translation.width > 50 {
                                    // Swipe right - previous page
                                    previousPage()
                                }
                            }
                    )
            } else {
                ContentUnavailableView {
                    Label("Unable to Load PDF", systemImage: "doc.fill")
                } description: {
                    Text("The PDF file could not be displayed")
                }
            }
            
            // Page Navigation
            if totalPages > 1 {
                pageNavigationBar
                    .padding(.top, 12)
            }
        }
        .onAppear {
            loadPDF()
        }
    }
    
    private var pageNavigationBar: some View {
        HStack(spacing: 20) {
            Button {
                previousPage()
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
            }
            .disabled(currentPage == 0)
            
            // Page indicator
            HStack(spacing: 8) {
                Text("Page")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("\(currentPage + 1)")
                    .font(.headline)
                    .monospacedDigit()
                
                Text("of \(totalPages)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
            
            Button {
                nextPage()
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
            }
            .disabled(currentPage >= totalPages - 1)
        }
    }
    
    private func loadPDF() {
        if let document = PDFDocument(data: pdfData) {
            self.pdfDocument = document
            self.totalPages = document.pageCount
        }
    }
    
    private func nextPage() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if currentPage < totalPages - 1 {
                currentPage += 1
            }
        }
    }
    
    private func previousPage() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if currentPage > 0 {
                currentPage -= 1
            }
        }
    }
}

// MARK: - PDF Page Renderer
struct PDFPageRenderer: UIViewRepresentable {
    let document: PDFDocument
    let pageIndex: Int
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.displayMode = .singlePage
        pdfView.autoScales = true
        pdfView.backgroundColor = .systemBackground
        pdfView.document = document
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let page = document.page(at: pageIndex) {
            pdfView.go(to: page)
        }
    }
}

// MARK: - PDF Thumbnail Grid
struct PDFThumbnailGrid: View {
    let pdfData: Data
    let onPageSelected: (Int) -> Void
    
    @State private var thumbnails: [UIImage] = []
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading pages...")
            } else if thumbnails.isEmpty {
                Text("No pages available")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(Array(thumbnails.enumerated()), id: \.offset) { index, thumbnail in
                            Button {
                                onPageSelected(index)
                            } label: {
                                VStack(spacing: 4) {
                                    Image(uiImage: thumbnail)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .shadow(radius: 2)
                                    
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            generateThumbnails()
        }
    }
    
    private func generateThumbnails() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let document = PDFDocument(data: pdfData) else {
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }
            
            var images: [UIImage] = []
            let thumbnailSize = CGSize(width: 150, height: 200)
            
            for i in 0..<document.pageCount {
                if let page = document.page(at: i) {
                    let thumbnail = page.thumbnail(of: thumbnailSize, for: .mediaBox)
                    images.append(thumbnail)
                }
            }
            
            DispatchQueue.main.async {
                thumbnails = images
                isLoading = false
            }
        }
    }
}

// MARK: - Compact PDF Preview
struct PDFPreviewCard: View {
    let pdfData: Data
    @State private var thumbnail: UIImage?
    @State private var pageCount: Int = 0
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .shadow(radius: 2)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 80)
                    .overlay {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(.secondary)
                    }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Label("PDF Document", systemImage: "doc.richtext")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(pageCount) page\(pageCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            loadPreview()
        }
    }
    
    private func loadPreview() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let document = PDFDocument(data: pdfData) else { return }
            
            let count = document.pageCount
            var thumb: UIImage?
            
            if let firstPage = document.page(at: 0) {
                thumb = firstPage.thumbnail(of: CGSize(width: 120, height: 160), for: .mediaBox)
            }
            
            DispatchQueue.main.async {
                pageCount = count
                thumbnail = thumb
            }
        }
    }
}

#Preview("PDF Page View") {
    // Note: This preview requires actual PDF data
    VStack {
        Text("PDF Preview would appear here")
            .foregroundStyle(.secondary)
    }
}
