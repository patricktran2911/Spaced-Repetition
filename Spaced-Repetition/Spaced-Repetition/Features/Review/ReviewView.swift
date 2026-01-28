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
    @State private var cardRotation: Double = 0
    @State private var showFullScreenPDF = false
    
    var body: some View {
        VStack(spacing: 0) {
            progressHeader
            
            ScrollView {
                VStack(spacing: 20) {
                    flashcard
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    if !store.showAnswer {
                        Label("Tap card to reveal answer", systemImage: "hand.tap")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Divider()
            bottomActionArea
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { store.send(.cancelTapped) }
            }
        }
        .disabled(store.isSubmitting)
        .overlay {
            if store.isSubmitting {
                SavingOverlay(message: "Saving...")
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
            FlashcardBackView(item: store.item) { _ in
                showFullScreenPDF = true
            }
            .rotation3DEffect(.degrees(cardRotation - 180), axis: (x: 0, y: 1, z: 0))
            .opacity(cardRotation > 90 ? 1 : 0)
            
            FlashcardFrontView(
                item: store.item,
                mediaPreview: AnyView(MediaPreviewView(item: store.item))
            )
            .rotation3DEffect(.degrees(cardRotation), axis: (x: 0, y: 1, z: 0))
            .opacity(cardRotation < 90 ? 1 : 0)
        }
        .onTapGesture {
            if !store.showAnswer {
                flipCard()
            }
        }
    }
    
    // MARK: - Bottom Action Area
    private var bottomActionArea: some View {
        VStack(spacing: 16) {
            if !store.showAnswer {
                RevealAnswerView(onReveal: flipCard)
            } else {
                ReviewRatingView(interval: store.item.interval) { quality in
                    store.send(.rateQuality(quality))
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            store.send(.showAnswerTapped)
        }
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