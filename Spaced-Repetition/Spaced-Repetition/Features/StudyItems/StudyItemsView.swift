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
            libraryList
                .navigationTitle("Library")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            store.send(.addItemTapped)
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
        } detail: {
            detailContent
        }
        .onAppear { store.send(.onAppear) }
        .sheet(item: $store.scope(state: \.addItem, action: \.addItem)) { addStore in
            NavigationStack { AddStudyItemView(store: addStore) }
        }
        .sheet(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
            NavigationStack { StudyItemDetailView(store: detailStore) }
        }
    }
    
    // MARK: - iPhone Layout
    private var iPhoneLayout: some View {
        ZStack {
            mainContent
            
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
    
    // MARK: - Library List (iPad Sidebar)
    private var libraryList: some View {
        VStack(spacing: 0) {
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
            .padding(.vertical, 12)
            
            Divider()
            
            if store.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.items.isEmpty {
                emptyLibraryView
            } else if store.filteredItems.isEmpty && !store.searchText.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(.tertiary)
                    Text("No results found")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.filteredItems) { item in
                            LibraryMenuRow(item: item, isSelected: store.selectedItemId == item.id)
                                .onTapGesture {
                                    store.send(.selectItem(item.id))
                                }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Detail Content (iPad)
    @ViewBuilder
    private var detailContent: some View {
        if store.isLoading {
            ProgressView("Loading...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let item = store.selectedItem {
            NavigationStack {
                LibraryContentView(item: item) {
                    store.send(.editItemTapped(item))
                }
                .navigationTitle(item.title)
                .navigationBarTitleDisplayMode(.inline)
            }
        } else if store.items.isEmpty {
            emptyStateView
        } else {
            selectLecturePrompt
        }
    }
    
    // MARK: - Main Content (iPhone)
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
            
            ScrollView {
                LazyVStack(spacing: 0) {
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
    
    // MARK: - Empty Library View
    private var emptyLibraryView: some View {
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
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
