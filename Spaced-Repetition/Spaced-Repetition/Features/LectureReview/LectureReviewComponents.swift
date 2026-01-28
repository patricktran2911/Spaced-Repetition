//
//  LectureReviewComponents.swift
//  Spaced-Repetition
//
//  Components for the Lecture Review view.
//

import SwiftUI

// MARK: - Lecture Row View
struct LectureRowView: View {
    let item: StudyItemState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if !item.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(item.tags.prefix(3), id: \.self) { tag in
                                DisplayTagChip(tag: tag, color: .purple)
                            }
                            if item.tags.count > 3 {
                                Text("+\(item.tags.count - 3)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Status indicator
                statusBadge
            }
            
            // Preview
            Text(item.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            
            // Footer with stats
            HStack(spacing: 16) {
                // Media indicators
                HStack(spacing: 8) {
                    if !item.allImages.isEmpty {
                        Label("\(item.allImages.count)", systemImage: "photo")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    
                    if item.pdfData != nil {
                        Label("1", systemImage: "doc.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                
                Spacer()
                
                // Review stats
                HStack(spacing: 12) {
                    Label("\(item.reviewCount)", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if item.interval > 0 {
                        Label("\(item.interval)d", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        if item.isDue {
            Text("Due")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange)
                .foregroundStyle(.white)
                .clipShape(Capsule())
        } else {
            Text("In \(item.daysUntilReview)d")
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.15))
                .foregroundStyle(.green)
                .clipShape(Capsule())
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
                    headerSection
                    Divider()
                    contentSection
                    
                    if !item.allImages.isEmpty {
                        imagesSection
                    }
                    
                    if item.pdfData != nil {
                        pdfSection
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { onDismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Label("Review Stats", systemImage: "chart.bar")
                        Text("Reviews: \(item.reviewCount)")
                        Text("Interval: \(item.interval) days")
                        Text("Ease: \(String(format: "%.1f", item.easeFactor))")
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                reviewButton
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
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.title)
                .font(.title.bold())
            
            if !item.tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(item.tags, id: \.self) { tag in
                        DisplayTagChip(tag: tag, color: .purple)
                    }
                }
            }
            
            // Stats row
            HStack(spacing: 20) {
                StatDisplayItem(
                    title: "Created",
                    value: item.createdAt.formatted(date: .abbreviated, time: .omitted),
                    icon: "calendar"
                )
                StatDisplayItem(
                    title: "Reviews",
                    value: "\(item.reviewCount)",
                    icon: "checkmark.circle"
                )
                if item.isDue {
                    StatDisplayItem(
                        title: "Due",
                        value: "Now",
                        icon: "clock.badge.exclamationmark",
                        color: .orange
                    )
                } else {
                    StatDisplayItem(
                        title: "Next",
                        value: "In \(item.daysUntilReview)d",
                        icon: "clock",
                        color: .green
                    )
                }
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text(item.content)
                .font(.body)
                .lineSpacing(6)
        }
    }
    
    // MARK: - Images Section
    private var imagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attachments")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            ImageGalleryView(images: item.allImages)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - PDF Section
    @ViewBuilder
    private var pdfSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Documents")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            if let pdfData = item.pdfData {
                PDFPreviewCard(pdfData: pdfData)
            }
        }
    }
    
    // MARK: - Review Button
    private var reviewButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            PrimaryActionButton(
                title: "Mark as Reviewed",
                icon: "checkmark.circle.fill"
            ) {
                showingReviewOptions = true
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
}
