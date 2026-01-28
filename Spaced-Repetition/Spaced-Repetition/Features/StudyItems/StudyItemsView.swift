//
//  StudyItemsView.swift
//  Spaced-Repetition
//
//  Library view with full-screen slide menu for browsing lectures.
//

import SwiftUI
import ComposableArchitecture

struct StudyItemsView: View {
    @Bindable var store: StoreOf<StudyItemsFeature>
    @State private var showMenu = false
    
    var body: some View {
        ZStack {
            // Main content
            mainContent
            
            // Full screen slide menu
            if showMenu {
                fullScreenMenu
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showMenu)
        .onAppear { store.send(.onAppear) }
        .sheet(item: $store.scope(state: \.addItem, action: \.addItem)) { addStore in
            NavigationStack { AddStudyItemView(store: addStore) }
        }
        .sheet(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
            NavigationStack { StudyItemDetailView(store: detailStore) }
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let item = store.selectedItem {
                    LibraryContentView(item: item) {
                        store.send(.editItemTapped(item))
                    }
                } else if store.items.isEmpty {
                    emptyStateView
                } else {
                    selectLecturePrompt
                }
            }
            .navigationTitle(store.selectedItem?.title ?? "Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation { showMenu = true }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "list.bullet")
                                .font(.title3)
                            if store.items.count > 0 && !showMenu {
                                Text("\(store.items.count)")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Full Screen Menu
    private var fullScreenMenu: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Library")
                    .font(.largeTitle.bold())
                Spacer()
                Button {
                    withAnimation { showMenu = false }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .padding(.top, 8)
            
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search lectures...", text: $store.searchText)
                if !store.searchText.isEmpty {
                    Button { store.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.bottom, 12)
            
            Divider()
            
            // List with Add button at top
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Add new lecture button
                    Button {
                        store.send(.addItemTapped)
                        withAnimation { showMenu = false }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "plus")
                                    .font(.title3.bold())
                                    .foregroundStyle(.white)
                            }
                            
                            Text("Add New Lecture")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.accentColor)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    
                    Divider().padding(.leading, 68)
                    
                    // Lectures list
                    if store.filteredItems.isEmpty && !store.searchText.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundStyle(.tertiary)
                            Text("No results found")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        ForEach(store.filteredItems) { item in
                            LibraryMenuRow(item: item, isSelected: store.selectedItemId == item.id)
                                .onTapGesture {
                                    store.send(.selectItem(item.id))
                                    withAnimation { showMenu = false }
                                }
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 {
                        withAnimation { showMenu = false }
                    }
                }
        )
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "books.vertical")
                .font(.system(size: 70))
                .foregroundStyle(.blue.opacity(0.6))
            
            Text("Your Library is Empty")
                .font(.title2.bold())
            
            Text("Start building your knowledge base\nby adding your first lecture.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                store.send(.addItemTapped)
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Lecture")
                }
                .font(.headline)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Select Lecture Prompt
    private var selectLecturePrompt: some View {
        VStack(spacing: 24) {
            Image(systemName: "hand.tap")
                .font(.system(size: 50))
                .foregroundStyle(.blue.opacity(0.7))
            
            Text("Select a Lecture")
                .font(.title2.bold())
            
            Text("Open the menu to browse\nyour lectures")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                withAnimation { showMenu = true }
            } label: {
                HStack {
                    Image(systemName: "list.bullet")
                    Text("Browse Library")
                }
                .font(.headline)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    StudyItemsView(store: Store(initialState: StudyItemsFeature.State()) { StudyItemsFeature() } withDependencies: { $0.databaseClient = .previewValue })
}
