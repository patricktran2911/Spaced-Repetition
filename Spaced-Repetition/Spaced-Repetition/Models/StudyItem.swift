//
//  StudyItem.swift
//  Spaced-Repetition
//
//  Created by Patrick Tran on 1/20/26.
//

import Foundation
import SwiftData

@Model
final class StudyItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    @Attribute(.externalStorage) var imageData: Data?  // Legacy single image
    @Attribute(.externalStorage) var imagesData: [Data]  // Multiple images
    @Attribute(.externalStorage) var pdfData: Data?  // Legacy single PDF
    @Attribute(.externalStorage) var pdfDataArray: [Data]  // Multiple PDFs
    var pdfURL: URL?  // Legacy URL reference
    var url: URL?  // Legacy single URL
    var urls: [URL]  // Multiple reference URLs
    var createdAt: Date
    var nextReviewDate: Date
    var reviewCount: Int
    var easeFactor: Double
    var interval: Int
    var tags: [String]
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        imageData: Data? = nil,
        imagesData: [Data] = [],
        pdfData: Data? = nil,
        pdfDataArray: [Data] = [],
        pdfURL: URL? = nil,
        url: URL? = nil,
        urls: [URL] = [],
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
        self.pdfDataArray = pdfDataArray
        self.pdfURL = pdfURL
        self.url = url
        self.urls = urls
        self.createdAt = createdAt
        self.nextReviewDate = nextReviewDate
        self.reviewCount = reviewCount
        self.easeFactor = easeFactor
        self.interval = interval
        self.tags = tags
    }
}

extension StudyItem {
    static var mockItems: [StudyItem] {
        [
            StudyItem(title: "Swift Basics", content: "Swift is a powerful programming language for iOS development."),
            StudyItem(title: "SwiftUI Fundamentals", content: "SwiftUI is a declarative framework for building user interfaces."),
            StudyItem(title: "TCA Architecture", content: "The Composable Architecture helps build applications in a consistent and understandable way.")
        ]
    }
}
