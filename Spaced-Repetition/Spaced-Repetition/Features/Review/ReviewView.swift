//
//  ReviewView.swift
//  Spaced-Repetition
//
//  Created by Patrick Tran on 1/20/26.
//

import SwiftUI
import ComposableArchitecture

struct ReviewView: View {
    @Bindable var store: StoreOf<ReviewFeature>
    @State private var isFlipped = false
    @State private var cardRotation: Double = 0
    @State private var showFullScreenPDF = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            progressHeader
            
            // Flashcard area
            ScrollView {
                VStack(spacing: 20) {
                    // The Flashcard
                    flashcard
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    // Tap hint
                    if !store.showAnswer {
                        Label("Tap card to reveal answer", systemImage: "hand.tap")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Divider()
            
            // Bottom action area
            bottomActionArea
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    store.send(.cancelTapped)
                }
            }
        }
        .disabled(store.isSubmitting)
        .overlay {
            if store.isSubmitting {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Saving...")
                            .font(.subheadline)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .fullScreenCover(isPresented: $showFullScreenPDF) {
            if let pdfData = store.item.pdfData {
                NavigationStack {
                    PDFPageView(pdfData: pdfData)
                        .navigationTitle("PDF Document")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showFullScreenPDF = false }
                            }
                        }
                }
            }
        }
    }
    
    // MARK: - Progress Header
    private var progressHeader: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Review #\(store.item.reviewCount + 1)")
                    .font(.headline)
                Text(store.item.tags.first ?? "No tags")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Stats
            HStack(spacing: 12) {
                StatBadge(icon: "calendar", value: "\(store.item.interval)d")
                StatBadge(icon: "speedometer", value: String(format: "%.1f", store.item.easeFactor))
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Flashcard
    private var flashcard: some View {
        ZStack {
            // Back of card (Answer)
            cardBack
                .rotation3DEffect(.degrees(cardRotation - 180), axis: (x: 0, y: 1, z: 0))
                .opacity(cardRotation > 90 ? 1 : 0)
            
            // Front of card (Question)
            cardFront
                .rotation3DEffect(.degrees(cardRotation), axis: (x: 0, y: 1, z: 0))
                .opacity(cardRotation < 90 ? 1 : 0)
        }
        .onTapGesture {
            if !store.showAnswer {
                flipCard()
            }
        }
    }
    
    private var cardFront: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question label
            HStack {
                Label("QUESTION", systemImage: "questionmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                Spacer()
            }
            
            // Title/Question
            Text(store.item.title)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.leading)
            
            Spacer(minLength: 20)
            
            // Media preview
            if !store.item.allImages.isEmpty || store.item.pdfData != nil {
                mediaPreview
            }
            
            Spacer(minLength: 20)
            
            // Flip hint at bottom
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
    
    private var cardBack: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Answer label
            HStack {
                Label("ANSWER", systemImage: "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                Spacer()
            }
            
            // Full content - Question + Answer
            VStack(alignment: .leading, spacing: 12) {
                Text(store.item.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                Text(store.item.content)
                    .font(.body)
                    .multilineTextAlignment(.leading)
            }
            
            // Media (images/PDF)
            if !store.item.allImages.isEmpty {
                ImageGalleryView(images: store.item.allImages)
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if let pdfData = store.item.pdfData {
                Button {
                    showFullScreenPDF = true
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
    
    private var mediaPreview: some View {
        HStack(spacing: 12) {
            if !store.item.allImages.isEmpty {
                HStack(spacing: -8) {
                    ForEach(Array(store.item.allImages.prefix(3).enumerated()), id: \.offset) { index, data in
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
                    if store.item.allImages.count > 3 {
                        Text("+\(store.item.allImages.count - 3)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text("\(store.item.allImages.count) image\(store.item.allImages.count > 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if store.item.pdfData != nil {
                Label("PDF attached", systemImage: "doc.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Bottom Action Area
    private var bottomActionArea: some View {
        VStack(spacing: 16) {
            if !store.showAnswer {
                VStack(spacing: 12) {
                    Text("Think about your answer...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        flipCard()
                    } label: {
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
            } else {
                VStack(spacing: 12) {
                    Text("How well did you know this?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    // Simplified 4-button rating
                    HStack(spacing: 12) {
                        RatingButton(
                            title: "Again",
                            subtitle: "< 1 min",
                            color: .red,
                            action: { store.send(.rateQuality(0)) }
                        )
                        
                        RatingButton(
                            title: "Hard",
                            subtitle: "~1 day",
                            color: .orange,
                            action: { store.send(.rateQuality(2)) }
                        )
                        
                        RatingButton(
                            title: "Good",
                            subtitle: "~\(max(1, store.item.interval)) days",
                            color: .blue,
                            action: { store.send(.rateQuality(4)) }
                        )
                        
                        RatingButton(
                            title: "Easy",
                            subtitle: "~\(max(1, store.item.interval * 2)) days",
                            color: .green,
                            action: { store.send(.rateQuality(5)) }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Flip Animation
    private func flipCard() {
        withAnimation(.spring(duration: 0.5)) {
            cardRotation = 180
        }
        
        // Slight delay to update state after animation starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            store.send(.showAnswerTapped)
        }
    }
}

// MARK: - Supporting Views
struct StatBadge: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .clipShape(Capsule())
    }
}

struct RatingButton: View {
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Review") {
    NavigationStack {
        ReviewView(
            store: Store(
                initialState: ReviewFeature.State(
                    item: StudyItemState(
                        title: "What is the capital of France?",
                        content: "Paris is the capital of France. It is known as the City of Light and is famous for the Eiffel Tower, Louvre Museum, and Notre-Dame Cathedral.",
                        tags: ["Geography", "Europe"]
                    )
                )
            ) {
                ReviewFeature()
            }
        )
    }
}