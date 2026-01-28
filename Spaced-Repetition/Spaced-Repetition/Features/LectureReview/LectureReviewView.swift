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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .regular {
            iPadLayout
        } else {
            iPhoneLayout
        }
    }
    
    // MARK: - iPad Layout
    private var iPadLayout: some View {
        NavigationSplitView {
            filterSidebar
                .navigationTitle("Review")
        } detail: {
            NavigationStack {
                lectureContent
                    .navigationTitle(store.filter.rawValue)
                    .searchable(text: $store.searchText, prompt: "Search lectures...")
            }
        }
        .onAppear { store.send(.onAppear) }
        .onDisappear { store.send(.onDisappear) }
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
    
    // MARK: - Filter Sidebar (iPad)
    private var filterSidebar: some View {
        List {
            ForEach(LectureReviewFeature.State.Filter.allCases, id: \.self) { filter in
                Button {
                    store.send(.setFilter(filter))
                } label: {
                    HStack {
                        Label(filter.rawValue, systemImage: filter.icon)
                        Spacer()
                        if filter == .due && store.dueCount > 0 {
                            Text("\(store.dueCount)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }
                    }
                }
                .listRowBackground(store.filter == filter ? Color.accentColor.opacity(0.15) : Color.clear)
                .foregroundStyle(store.filter == filter ? Color.accentColor : .primary)
            }
        }
    }
    
    // MARK: - iPhone Layout
    private var iPhoneLayout: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterPicker
                lectureContent
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
    
    // MARK: - Lecture Content (Shared)
    @ViewBuilder
    private var lectureContent: some View {
        if store.isLoading {
            LoadingStateView(message: "Loading lectures...")
        } else if store.filteredItems.isEmpty {
            emptyStateView
        } else {
            lectureList
        }
    }
    
    // MARK: - Filter Picker (iPhone)
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
        EmptyStateView(
            icon: store.filter == .due ? "checkmark.circle" : "books.vertical",
            title: emptyStateTitle,
            message: emptyStateMessage
        )
    }
    
    private var emptyStateTitle: String {
        if !store.searchText.isEmpty {
            return "No Results"
        }
        switch store.filter {
        case .due: return "All Caught Up! 🎉"
        case .all: return "No Lectures Yet"
        case .recent: return "No Recent Reviews"
        }
    }
    
    private var emptyStateMessage: String {
        if !store.searchText.isEmpty {
            return "No lectures match your search."
        }
        switch store.filter {
        case .due: return "You've reviewed all your due items. Great job staying on top of your learning!"
        case .all: return "Add some lectures or notes to start your spaced repetition journey."
        case .recent: return "Start reviewing to build your learning history."
        }
    }
    
    // MARK: - Lecture List
    private var lectureList: some View {
        List {
            ForEach(store.filteredItems) { item in
                LectureRowView(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        store.send(.selectItem(item))
                    }
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    LectureReviewView(
        store: Store(initialState: LectureReviewFeature.State()) {
            LectureReviewFeature()
        }
    )
}
