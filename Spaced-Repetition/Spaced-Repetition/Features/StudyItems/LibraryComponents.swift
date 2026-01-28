//
//  LibraryComponents.swift
//  Spaced-Repetition
//
//  Components for the Library (StudyItems) view.
//

import SwiftUI

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
            #if os(iOS)
            .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 900 : .infinity)
            #endif
            .frame(maxWidth: .infinity)
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
