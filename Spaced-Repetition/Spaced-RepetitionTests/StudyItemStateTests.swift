//
//  StudyItemStateTests.swift
//  Spaced-RepetitionTests
//
//  Created by Patrick Tran on 1/20/26.
//

import XCTest
@testable import Spaced_Repetition

final class StudyItemStateTests: XCTestCase {
    
    // MARK: - isDue Tests
    
    func testIsDueWithPastDate() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let item = StudyItemState(
            id: UUID(),
            title: "Test",
            content: "Content",
            nextReviewDate: pastDate
        )
        
        XCTAssertTrue(item.isDue)
    }
    
    func testIsDueWithCurrentDate() {
        let item = StudyItemState(
            id: UUID(),
            title: "Test",
            content: "Content",
            nextReviewDate: Date()
        )
        
        XCTAssertTrue(item.isDue)
    }
    
    func testIsDueWithFutureDate() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let item = StudyItemState(
            id: UUID(),
            title: "Test",
            content: "Content",
            nextReviewDate: futureDate
        )
        
        XCTAssertFalse(item.isDue)
    }
    
    // MARK: - daysUntilReview Tests
    
    func testDaysUntilReviewWithFutureDate() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        let item = StudyItemState(
            id: UUID(),
            title: "Test",
            content: "Content",
            nextReviewDate: futureDate
        )
        
        // Allow +/- 1 day variance due to timing around midnight
        XCTAssertGreaterThanOrEqual(item.daysUntilReview, 4)
        XCTAssertLessThanOrEqual(item.daysUntilReview, 5)
    }
    
    func testDaysUntilReviewWithPastDate() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let item = StudyItemState(
            id: UUID(),
            title: "Test",
            content: "Content",
            nextReviewDate: pastDate
        )
        
        // Past dates should return 0 or negative
        XCTAssertLessThanOrEqual(item.daysUntilReview, 0)
    }
    
    func testDaysUntilReviewToday() {
        let item = StudyItemState(
            id: UUID(),
            title: "Test",
            content: "Content",
            nextReviewDate: Date()
        )
        
        XCTAssertEqual(item.daysUntilReview, 0)
    }
    
    // MARK: - Initialization Tests
    
    func testDefaultInitialization() {
        let item = StudyItemState(
            id: UUID(),
            title: "Test",
            content: "Content"
        )
        
        XCTAssertEqual(item.title, "Test")
        XCTAssertEqual(item.content, "Content")
        XCTAssertEqual(item.reviewCount, 0)
        XCTAssertEqual(item.easeFactor, 2.5)
        XCTAssertEqual(item.interval, 0)
        XCTAssertTrue(item.tags.isEmpty)
        XCTAssertNil(item.imageData)
        XCTAssertNil(item.pdfURL)
    }
    
    func testFullInitialization() {
        let id = UUID()
        let imageData = Data([0x00, 0x01, 0x02])
        let pdfURL = URL(string: "https://example.com/test.pdf")!
        let createdAt = Date()
        let nextReviewDate = Date().addingTimeInterval(86400)
        let tags = ["swift", "ios"]
        
        let item = StudyItemState(
            id: id,
            title: "Test",
            content: "Content",
            imageData: imageData,
            pdfURL: pdfURL,
            createdAt: createdAt,
            nextReviewDate: nextReviewDate,
            reviewCount: 5,
            easeFactor: 2.8,
            interval: 10,
            tags: tags
        )
        
        XCTAssertEqual(item.id, id)
        XCTAssertEqual(item.title, "Test")
        XCTAssertEqual(item.content, "Content")
        XCTAssertEqual(item.imageData, imageData)
        XCTAssertEqual(item.pdfURL, pdfURL)
        XCTAssertEqual(item.createdAt, createdAt)
        XCTAssertEqual(item.nextReviewDate, nextReviewDate)
        XCTAssertEqual(item.reviewCount, 5)
        XCTAssertEqual(item.easeFactor, 2.8)
        XCTAssertEqual(item.interval, 10)
        XCTAssertEqual(item.tags, tags)
    }
    
    // MARK: - Equatable Tests
    
    func testEquatable() {
        let id = UUID()
        let fixedDate = Date(timeIntervalSince1970: 1000000000)
        let item1 = StudyItemState(
            id: id,
            title: "Test",
            content: "Content",
            createdAt: fixedDate,
            nextReviewDate: fixedDate
        )
        let item2 = StudyItemState(
            id: id,
            title: "Test",
            content: "Content",
            createdAt: fixedDate,
            nextReviewDate: fixedDate
        )
        
        XCTAssertEqual(item1, item2)
    }
    
    func testNotEquatableWithDifferentId() {
        let fixedDate = Date(timeIntervalSince1970: 1000000000)
        let item1 = StudyItemState(id: UUID(), title: "Test", content: "Content", createdAt: fixedDate, nextReviewDate: fixedDate)
        let item2 = StudyItemState(id: UUID(), title: "Test", content: "Content", createdAt: fixedDate, nextReviewDate: fixedDate)
        
        XCTAssertNotEqual(item1, item2)
    }
    
    func testNotEquatableWithDifferentContent() {
        let id = UUID()
        let fixedDate = Date(timeIntervalSince1970: 1000000000)
        let item1 = StudyItemState(id: id, title: "Test", content: "Content 1", createdAt: fixedDate, nextReviewDate: fixedDate)
        let item2 = StudyItemState(id: id, title: "Test", content: "Content 2", createdAt: fixedDate, nextReviewDate: fixedDate)
        
        XCTAssertNotEqual(item1, item2)
    }
    
    // MARK: - Identifiable Tests
    
    func testIdentifiable() {
        let id = UUID()
        let item = StudyItemState(id: id, title: "Test", content: "Content")
        
        XCTAssertEqual(item.id, id)
    }
}
