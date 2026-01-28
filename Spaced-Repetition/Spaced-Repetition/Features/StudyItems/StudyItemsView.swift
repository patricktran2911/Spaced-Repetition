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
                        store.send(.itemTapped(item))
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

// MARK: - Library Menu Row
struct LibraryMenuRow: View {
    let item: StudyItemState
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(item.isDue ? Color.orange : Color.green)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.accentColor : .primary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    if item.isDue {
                        Text("Due now").font(.caption).foregroundStyle(.orange)
                    } else {
                        Text("In \(item.daysUntilReview) days").font(.caption).foregroundStyle(.secondary)
                    }
                    
                    Text("•").foregroundStyle(.tertiary)
                    
                    Text("\(item.reviewCount) reviews").font(.caption).foregroundStyle(.secondary)
                    
                    if !item.allImages.isEmpty || item.pdfData != nil {
                        Spacer()
                        HStack(spacing: 4) {
                            if !item.allImages.isEmpty { Image(systemName: "photo") }
                            if item.pdfData != nil { Image(systemName: "doc.fill") }
                        }
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 14)
        .background(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
        .overlay(alignment: .bottom) {
            Divider().padding(.leading, 40)
        }
    }
}

// MARK: - Library Content View
struct LibraryContentView: View {
    let item: StudyItemState
    let onEdit: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Tags
                if !item.tags.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(item.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.purple.opacity(0.12))
                                .foregroundStyle(.purple)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                // Stats
                HStack(spacing: 20) {
                    LibStatLabel(icon: "calendar", text: item.createdAt.formatted(date: .abbreviated, time: .omitted))
                    LibStatLabel(icon: "checkmark.circle", text: "\(item.reviewCount) reviews")
                    if item.isDue {
                        LibStatLabel(icon: "clock.badge.exclamationmark", text: "Due", color: .orange)
                    } else {
                        LibStatLabel(icon: "clock", text: "\(item.daysUntilReview)d", color: .green)
                    }
                }
                
                Divider()
                
                // Content
                Text(item.content)
                    .font(.body)
                    .lineSpacing(6)
                
                // Images
                if !item.allImages.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Attachments").font(.headline).foregroundStyle(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(item.allImages.enumerated()), id: \.offset) { _, data in
                                    if let img = PlatformImage(data: data) {
                                        #if os(iOS)
                                        Image(uiImage: img).resizable().aspectRatio(contentMode: .fill)
                                            .frame(width: 180, height: 140).clipShape(RoundedRectangle(cornerRadius: 10))
                                        #else
                                        Image(nsImage: img).resizable().aspectRatio(contentMode: .fill)
                                            .frame(width: 180, height: 140).clipShape(RoundedRectangle(cornerRadius: 10))
                                        #endif
                                    }
                                }
                            }
                        }
                    }
                }
                
                // PDF
                if item.pdfData != nil {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.fill").font(.title2).foregroundStyle(.red)
                        VStack(alignment: .leading) {
                            Text("PDF Document").font(.subheadline.bold())
                            Text("Tap Edit to view").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Spacer(minLength: 120)
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                Button(action: onEdit) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit Lecture").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
    }
}

// MARK: - Library Stat Label
struct LibStatLabel: View {
    let icon: String
    let text: String
    var color: Color = .secondary
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .foregroundStyle(color)
    }
}

#Preview {
    StudyItemsView(store: Store(initialState: StudyItemsFeature.State()) { StudyItemsFeature() } withDependencies: { $0.databaseClient = .previewValue })
}
