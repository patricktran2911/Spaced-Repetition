//
//  ReviewComponents.swift
//  Spaced-Repetition
//
//  Components for the Review view.
//

import SwiftUI

// MARK: - Flashcard Front View
struct FlashcardFrontView: View {
    let item: StudyItemState
    let mediaPreview: AnyView
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("QUESTION", systemImage: "questionmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                Spacer()
            }
            
            Text(item.title)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.leading)
            
            Spacer(minLength: 20)
            
            if !item.allImages.isEmpty || item.pdfData != nil {
                mediaPreview
            }
            
            Spacer(minLength: 20)
            
            HStack {
                Spacer()
                Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 350)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Flashcard Back View
struct FlashcardBackView: View {
    let item: StudyItemState
    let onPDFTapped: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("ANSWER", systemImage: "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(item.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                Text(item.content)
                    .font(.body)
                    .multilineTextAlignment(.leading)
            }
            
            if !item.allImages.isEmpty {
                ImageGalleryView(images: item.allImages)
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if let pdfData = item.pdfData {
                Button {
                    onPDFTapped(0)
                } label: {
                    PDFPreviewCard(pdfData: pdfData)
                }
                .buttonStyle(.plain)
            }
            
            Spacer(minLength: 10)
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 350)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Media Preview View
struct MediaPreviewView: View {
    let item: StudyItemState
    
    var body: some View {
        HStack(spacing: 12) {
            if !item.allImages.isEmpty {
                HStack(spacing: -8) {
                    ForEach(Array(item.allImages.prefix(3).enumerated()), id: \.offset) { index, data in
                        if let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemBackground), lineWidth: 2)
                                )
                        }
                    }
                    if item.allImages.count > 3 {
                        Text("+\(item.allImages.count - 3)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text("\(item.allImages.count) image\(item.allImages.count > 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if item.pdfData != nil {
                Label("PDF attached", systemImage: "doc.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Review Rating View
struct ReviewRatingView: View {
    let interval: Int
    let onRate: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("How well did you know this?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                RatingButton(
                    title: "Again",
                    subtitle: "< 1 min",
                    color: .red,
                    action: { onRate(0) }
                )
                
                RatingButton(
                    title: "Hard",
                    subtitle: "~1 day",
                    color: .orange,
                    action: { onRate(2) }
                )
                
                RatingButton(
                    title: "Good",
                    subtitle: "~\(max(1, interval)) days",
                    color: .blue,
                    action: { onRate(4) }
                )
                
                RatingButton(
                    title: "Easy",
                    subtitle: "~\(max(1, interval * 2)) days",
                    color: .green,
                    action: { onRate(5) }
                )
            }
        }
    }
}

// MARK: - Reveal Answer View
struct RevealAnswerView: View {
    let onReveal: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Think about your answer...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button(action: onReveal) {
                HStack {
                    Image(systemName: "eye.fill")
                    Text("Reveal Answer")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}
