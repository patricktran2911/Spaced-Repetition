//
//  StudyItemState.swift
//  Spaced-Repetition
//
//  Created by Patrick Tran on 1/20/26.
//

import Foundation

// MARK: - StudyItemState (Value type for TCA)
struct StudyItemState: Equatable, Identifiable, Sendable {
    let id: UUID
    var title: String
    var content: String
    var imageData: Data?  // Legacy single image
    var imagesData: [Data]  // Multiple images
    var pdfData: Data?  // PDF binary data
    var pdfURL: URL?  // Legacy URL reference
    var createdAt: Date
    var nextReviewDate: Date
    var reviewCount: Int
    var easeFactor: Double
    var interval: Int
    var tags: [String]
    
    // Computed property to get all images (combining legacy + new)
    var allImages: [Data] {
        var images = imagesData
        if let legacy = imageData, !images.contains(legacy) {
            images.insert(legacy, at: 0)
        }
        return images
    }
    
    var hasMedia: Bool {
        !allImages.isEmpty || pdfData != nil || pdfURL != nil
    }
    
    init(from item: StudyItem) {
        self.id = item.id
        self.title = item.title
        self.content = item.content
        self.imageData = item.imageData
        self.imagesData = item.imagesData
        self.pdfData = item.pdfData
        self.pdfURL = item.pdfURL
        self.createdAt = item.createdAt
        self.nextReviewDate = item.nextReviewDate
        self.reviewCount = item.reviewCount
        self.easeFactor = item.easeFactor
        self.interval = item.interval
        self.tags = item.tags
    }
    
    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        imageData: Data? = nil,
        imagesData: [Data] = [],
        pdfData: Data? = nil,
        pdfURL: URL? = nil,
        createdAt: Date = Date(),
        nextReviewDate: Date = Date(),
        reviewCount: Int = 0,
        easeFactor: Double = 2.5,
        interval: Int = 0,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.imageData = imageData
        self.imagesData = imagesData
        self.pdfData = pdfData
        self.pdfURL = pdfURL
        self.createdAt = createdAt
        self.nextReviewDate = nextReviewDate
        self.reviewCount = reviewCount
        self.easeFactor = easeFactor
        self.interval = interval
        self.tags = tags
    }
    
    func toStudyItem() -> StudyItem {
        StudyItem(
            id: id,
            title: title,
            content: content,
            imageData: imageData,
            imagesData: imagesData,
            pdfData: pdfData,
            pdfURL: pdfURL,
            createdAt: createdAt,
            nextReviewDate: nextReviewDate,
            reviewCount: reviewCount,
            easeFactor: easeFactor,
            interval: interval,
            tags: tags
        )
    }
    
    var isDue: Bool {
        nextReviewDate <= Date()
    }
    
    var daysUntilReview: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: nextReviewDate)
        return max(0, components.day ?? 0)
    }
}