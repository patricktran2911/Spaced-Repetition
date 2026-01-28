//
//  LectureReviewView.swift
//  Spaced-Repetition
//
//  A lecture/note-based review system - browse, search, read full notes, and mark as reviewed.
//

import SwiftUI
import ComposableArchitecture

struct LectureReviewView: View {
    @Bindable var store: StoreOf<LectureReviewFeature>
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter picker
                filterPicker
                
                // Content
                if store.isLoading {
                    ProgressView("Loading lectures...")
                        .frame(maxHeight: .infinity)
                } else if store.filteredItems.isEmpty {
                    emptyStateView
                } else {
                    lectureList
                }
            }
            .navigationTitle("Review")
            .searchable(text: $store.searchText, prompt: "Search lectures...")
            .onAppear { store.send(.onAppear) }
            .onDisappear { store.send(.onDisappear) }
        }
        .sheet(isPresented: $store.showingReviewSheet) {
            if let item = store.selectedItem {
                LectureDetailSheet(
                    item: item,
                    onDismiss: { store.send(.dismissItem) },
                    onMarkReviewed: { quality in store.send(.markAsReviewed(quality: quality)) }
                )
            }
        }
    }
    
    // MARK: - Filter Picker
    private var filterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(LectureReviewFeature.State.Filter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        icon: filter.icon,
                        isSelected: store.filter == filter,
                        badge: filter == .due ? store.dueCount : nil
                    ) {
                        store.send(.setFilter(filter))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: store.filter == .due ? "checkmark.circle" : "books.vertical")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text(emptyStateTitle)
                .font(.title2.bold())
            
            Text(emptyStateMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var emptyStateTitle: String {
        if !store.searchText.isEmpty { return "No Results" }
        switch store.filter {
        case .due: return "All Caught Up! 🎉"
        case .all: return "No Lectures Yet"
        case .recent: return "No Recent Reviews"
        }
    }
    
    private var emptyStateMessage: String {
        if !store.searchText.isEmpty { return "No lectures match your search." }
        switch store.filter {
        case .due: return "You've reviewed all your due items. Great job!"
        case .all: return "Add some lectures to start your spaced repetition journey."
        case .recent: return "Start reviewing to build your learning history."
        }
    }
    
    // MARK: - Lecture List
    private var lectureList: some View {
        List {
            ForEach(store.filteredItems) { item in
                LectureRowView(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture { store.send(.selectItem(item)) }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var badge: Int?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.subheadline)
                Text(title).font(.subheadline.weight(.medium))
                if let badge = badge, badge > 0 {
                    Text("\(badge)")
                        .font(.caption.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.red)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Lecture Row View
struct LectureRowView: View {
    let item: StudyItemState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title).font(.headline).lineLimit(2)
                    if !item.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(item.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.purple.opacity(0.15))
                                    .foregroundStyle(.purple)
                                    .clipShape(Capsule())
                            }
                            if item.tags.count > 3 {
                                Text("+\(item.tags.count - 3)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Spacer()
                statusBadge
            }
            
            Text(item.content).font(.subheadline).foregroundStyle(.secondary).lineLimit(3)
            
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    if !item.allImages.isEmpty {
                        Label("\(item.allImages.count)", systemImage: "photo").font(.caption).foregroundStyle(.blue)
                    }
                    if item.pdfData != nil {
                        Label("PDF", systemImage: "doc.fill").font(.caption).foregroundStyle(.red)
                    }
                }
                Spacer()
                HStack(spacing: 12) {
                    Label("\(item.reviewCount)", systemImage: "checkmark.circle").font(.caption).foregroundStyle(.secondary)
                    if item.interval > 0 {
                        Label("\(item.interval)d", systemImage: "clock").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        if item.isDue {
            Text("Due").font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color.orange).foregroundStyle(.white).clipShape(Capsule())
        } else {
            Text("In \(item.daysUntilReview)d").font(.caption).padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color.green.opacity(0.15)).foregroundStyle(.green).clipShape(Capsule())
        }
    }
}

// MARK: - Lecture Detail Sheet
struct LectureDetailSheet: View {
    let item: StudyItemState
    let onDismiss: () -> Void
    let onMarkReviewed: (Int) -> Void
    @State private var showingReviewOptions = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(item.title).font(.title.bold())
                        if !item.tags.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(item.tags, id: \.self) { tag in
                                    Text(tag).font(.subheadline).padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(Color.purple.opacity(0.15)).foregroundStyle(.purple).clipShape(Capsule())
                                }
                            }
                        }
                        HStack(spacing: 20) {
                            ReviewStatItem(icon: "calendar", value: item.createdAt.formatted(date: .abbreviated, time: .omitted), label: "Created")
                            ReviewStatItem(icon: "checkmark.circle", value: "\(item.reviewCount)", label: "Reviews")
                            if item.isDue {
                                ReviewStatItem(icon: "clock.badge.exclamationmark", value: "Now", label: "Due", color: .orange)
                            } else {
                                ReviewStatItem(icon: "clock", value: "In \(item.daysUntilReview)d", label: "Next", color: .green)
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    Divider()
                    
                    // Content
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes").font(.headline).foregroundStyle(.secondary)
                        Text(item.content).font(.body).lineSpacing(6)
                    }
                    
                    // Images
                    if !item.allImages.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Attachments").font(.headline).foregroundStyle(.secondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(item.allImages.enumerated()), id: \.offset) { _, imageData in
                                        if let uiImage = PlatformImage(data: imageData) {
                                            #if os(iOS)
                                            Image(uiImage: uiImage).resizable().aspectRatio(contentMode: .fill)
                                                .frame(width: 200, height: 150).clipShape(RoundedRectangle(cornerRadius: 12))
                                            #else
                                            Image(nsImage: uiImage).resizable().aspectRatio(contentMode: .fill)
                                                .frame(width: 200, height: 150).clipShape(RoundedRectangle(cornerRadius: 12))
                                            #endif
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // PDF
                    if item.pdfData != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Document").font(.headline).foregroundStyle(.secondary)
                            HStack {
                                Image(systemName: "doc.fill").font(.title).foregroundStyle(.red)
                                VStack(alignment: .leading) {
                                    Text("PDF Document").font(.subheadline.bold())
                                    Text("Tap to view").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Close") { onDismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Label("Review Stats", systemImage: "chart.bar")
                        Text("Reviews: \(item.reviewCount)")
                        Text("Interval: \(item.interval) days")
                        Text("Ease: \(String(format: "%.1f", item.easeFactor))")
                    } label: { Image(systemName: "info.circle") }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    Button { showingReviewOptions = true } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Mark as Reviewed").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
            }
        }
        .confirmationDialog("How well did you remember?", isPresented: $showingReviewOptions, titleVisibility: .visible) {
            Button("Perfect - I knew it! ✨") { onMarkReviewed(5) }
            Button("Good - With some thought 👍") { onMarkReviewed(4) }
            Button("OK - Needed effort 🤔") { onMarkReviewed(3) }
            Button("Hard - Struggled to recall 😓") { onMarkReviewed(2) }
            Button("Forgot - Need to relearn 😅") { onMarkReviewed(1) }
            Button("Cancel", role: .cancel) { }
        }
    }
}

// MARK: - Stat Item
struct ReviewStatItem: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = .secondary
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption)
                Text(value).font(.subheadline.bold())
            }
            .foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

#Preview {
    LectureReviewView(store: Store(initialState: LectureReviewFeature.State()) { LectureReviewFeature() })
}
