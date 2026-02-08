//
//  StudyItemDetailComponents.swift
//  Spaced-Repetition
//
//  Components for the Study Item Detail view.
//

import SwiftUI
import PhotosUI
import ComposableArchitecture

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Review Status Card
struct ReviewStatusCard: View {
    let item: StudyItemState
    let isEditing: Bool
    let onStartReview: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if item.isDue {
                        Label("Due Now", systemImage: "bell.badge.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                    } else {
                        Label("Next Review", systemImage: "calendar")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("in \(item.daysUntilReview) days")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Reviews")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(item.reviewCount)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            
            Divider()
            
            HStack {
                StatItem(title: "Interval", value: "\(item.interval)d")
                Spacer()
                StatItem(title: "Ease", value: String(format: "%.1f", item.easeFactor))
                Spacer()
                StatItem(title: "Created", value: item.createdAt.formatted(date: .abbreviated, time: .omitted))
            }
            
            Button(action: onStartReview) {
                Label("Start Review", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isEditing)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Item Editing View
struct ItemEditingView: View {
    @Bindable var store: StoreOf<StudyItemDetailFeature>
    @Binding var selectedPhotoItems: [PhotosPickerItem]
    let onShowPDFPicker: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Content Section
            EditableSectionCard(
                title: "Content",
                icon: "doc.text",
                subtitle: store.editedTitle.isEmpty ? "Add title and content" : store.editedTitle,
                count: nil,
                accentColor: .blue
            ) {
                store.send(.editSectionTapped(.content))
            }
            
            // Images Section
            EditableSectionCard(
                title: "Images",
                icon: "photo.on.rectangle.angled",
                subtitle: store.editedImagesData.isEmpty ? "Add images" : "\(store.editedImagesData.count) image\(store.editedImagesData.count == 1 ? "" : "s")",
                count: store.editedImagesData.count,
                accentColor: .green
            ) {
                store.send(.editSectionTapped(.images))
            }
            
            // PDFs Section
            EditableSectionCard(
                title: "PDF Documents",
                icon: "doc.text.fill",
                subtitle: store.editedPdfDataArray.isEmpty ? "Add PDF files" : "\(store.editedPdfDataArray.count) document\(store.editedPdfDataArray.count == 1 ? "" : "s")",
                count: store.editedPdfDataArray.count,
                accentColor: .red
            ) {
                store.send(.editSectionTapped(.pdfs))
            }
            
            // URLs Section
            EditableSectionCard(
                title: "Reference URLs",
                icon: "link",
                subtitle: store.editedUrls.isEmpty ? "Add URLs" : "\(store.editedUrls.count) link\(store.editedUrls.count == 1 ? "" : "s")",
                count: store.editedUrls.count,
                accentColor: .purple
            ) {
                store.send(.editSectionTapped(.urls))
            }
            
            // Tags Section
            EditableSectionCard(
                title: "Tags",
                icon: "tag.fill",
                subtitle: store.editedTags.isEmpty ? "Add tags" : store.editedTags.joined(separator: ", "),
                count: store.editedTags.count,
                accentColor: .orange
            ) {
                store.send(.editSectionTapped(.tags))
            }
        }
        .sheet(item: $store.activeEditSection.sending(\.editSectionTapped)) { section in
            sectionEditorView(for: section)
        }
    }
    
    @ViewBuilder
    private func sectionEditorView(for section: StudyItemDetailFeature.State.EditSection) -> some View {
        switch section {
        case .content:
            ContentEditorView(store: store)
        case .images:
            ImagesEditorView(store: store)
        case .pdfs:
            PDFsEditorView(store: store)
        case .urls:
            URLsEditorView(store: store)
        case .tags:
            TagsEditorView(store: store)
        }
    }
}

// MARK: - Editable Section Card
struct EditableSectionCard: View {
    let title: String
    let icon: String
    let subtitle: String
    let count: Int?
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(accentColor)
                    .frame(width: 44, height: 44)
                    .background(accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Content
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if let count, count > 0 {
                            Text("\(count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(accentColor)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Identifiable Extension
extension StudyItemDetailFeature.State.EditSection: Identifiable {
    var id: Self { self }
}
