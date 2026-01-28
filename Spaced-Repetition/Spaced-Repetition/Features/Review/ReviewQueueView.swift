//
//  ReviewQueueView.swift
//  Spaced-Repetition
//
//  Created by Patrick Tran on 1/20/26.
//

import SwiftUI
import ComposableArchitecture

struct ReviewQueueView: View {
    @Bindable var store: StoreOf<ReviewQueueFeature>
    @State private var currentTip = MemoryTip.random()
    
    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    ProgressView("Loading...")
                } else if store.dueItems.isEmpty {
                    allCaughtUpView
                } else {
                    reviewQueueContent
                }
            }
            .navigationTitle("Review")
            .onAppear {
                store.send(.onAppear)
            }
        }
        .sheet(item: $store.scope(state: \.reviewSession, action: \.reviewSession)) { store in
            NavigationStack {
                ReviewView(store: store)
            }
            .interactiveDismissDisabled()
        }
    }
    
    // MARK: - All Caught Up View
    private var allCaughtUpView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)
                
                // Celebration animation
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, options: .repeating.speed(0.5))
                
                VStack(spacing: 8) {
                    Text("All Caught Up!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("You have no items due for review.\nGreat job staying on top of your learning!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Memory tip card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("💡 While You Wait")
                            .font(.headline)
                        Spacer()
                        Button {
                            withAnimation {
                                currentTip = MemoryTip.random()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                        }
                    }
                    
                    MemoryTipCard(tip: currentTip)
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .padding()
        }
        .refreshable {
            store.send(.refreshItems)
        }
    }
    
    // MARK: - Review Queue Content
    private var reviewQueueContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Progress Section
                VStack(spacing: 12) {
                    HStack {
                        Text("\(store.dueItemsCount) items due")
                            .font(.headline)
                        Spacer()
                        Text("\(store.currentReviewIndex)/\(store.dueItemsCount) completed")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    ProgressView(value: store.progress)
                        .tint(.green)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Current Item Preview
                if let currentItem = store.currentItem {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Next Item")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(currentItem.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 16) {
                                Label("\(currentItem.reviewCount) reviews", systemImage: "checkmark.circle")
                                Label("Interval: \(currentItem.interval)d", systemImage: "calendar")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Button {
                            store.send(.startReviewTapped)
                        } label: {
                            Label("Start Review", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                
                // Upcoming Items
                if store.dueItems.count > 1 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Queue")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        ForEach(Array(store.dueItems.enumerated()), id: \.element.id) { index, item in
                            if index > store.currentReviewIndex {
                                HStack {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)
                                    
                                    Text(item.title)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    if item.imageData != nil {
                                        Image(systemName: "photo")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 8)
                                
                                if index < store.dueItems.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .refreshable {
            store.send(.refreshItems)
        }
    }
}

#Preview("With Items") {
    ReviewQueueView(
        store: Store(
            initialState: ReviewQueueFeature.State(
                dueItems: IdentifiedArray(uniqueElements: [
                    StudyItemState(title: "Swift Basics", content: "Learn Swift"),
                    StudyItemState(title: "SwiftUI", content: "Learn SwiftUI"),
                    StudyItemState(title: "TCA", content: "Learn TCA")
                ])
            )
        ) {
            ReviewQueueFeature()
        }
    )
}

#Preview("Empty") {
    ReviewQueueView(
        store: Store(
            initialState: ReviewQueueFeature.State()
        ) {
            ReviewQueueFeature()
        }
    )
}
