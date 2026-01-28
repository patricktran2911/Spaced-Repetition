//
//  DatabaseClient.swift
//  Spaced-Repetition
//

import Foundation
import ComposableArchitecture
import SwiftData
import CoreData

struct DatabaseClient: Sendable {
    var fetchStudyItems: @Sendable () async throws -> [StudyItemState]
    var fetchStudyItem: @Sendable (_ id: UUID) async throws -> StudyItemState?
    var saveStudyItem: @Sendable (_ item: StudyItemState) async throws -> Void
    var deleteStudyItem: @Sendable (_ id: UUID) async throws -> Void
    var updateStudyItem: @Sendable (_ item: StudyItemState) async throws -> Void
    var fetchDueItems: @Sendable () async throws -> [StudyItemState]
    var saveReviewSession: @Sendable (_ itemId: UUID, _ quality: Int, _ responseTime: TimeInterval) async throws -> Void
    var fetchReviewSessions: @Sendable (_ itemId: UUID) async throws -> [ReviewSessionState]
    var studyItemsStream: @Sendable () -> AsyncStream<[StudyItemState]>
}

struct ReviewSessionState: Equatable, Identifiable, Sendable {
    let id: UUID
    var itemId: UUID
    var reviewedAt: Date
    var quality: Int
    var responseTime: TimeInterval
}

@ModelActor
actor DatabaseService {
    func fetchStudyItems() throws -> [StudyItemState] {
        let descriptor = FetchDescriptor<StudyItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor).map { StudyItemState(from: $0) }
    }
    
    func fetchStudyItem(id: UUID) throws -> StudyItemState? {
        let descriptor = FetchDescriptor<StudyItem>(predicate: #Predicate { $0.id == id })
        guard let item = try modelContext.fetch(descriptor).first else { return nil }
        return StudyItemState(from: item)
    }
    
    func saveStudyItem(id: UUID, title: String, content: String, imageData: Data?, imagesData: [Data], pdfData: Data?, pdfURL: URL?, createdAt: Date, nextReviewDate: Date, reviewCount: Int, easeFactor: Double, interval: Int, tags: [String]) throws {
        let item = StudyItem(id: id, title: title, content: content, imageData: imageData, imagesData: imagesData, pdfData: pdfData, pdfURL: pdfURL, createdAt: createdAt, nextReviewDate: nextReviewDate, reviewCount: reviewCount, easeFactor: easeFactor, interval: interval, tags: tags)
        modelContext.insert(item)
        try modelContext.save()
    }
    
    func deleteStudyItem(id: UUID) throws {
        let descriptor = FetchDescriptor<StudyItem>(predicate: #Predicate { $0.id == id })
        if let item = try modelContext.fetch(descriptor).first {
            modelContext.delete(item)
            try modelContext.save()
        }
    }
    
    func updateStudyItem(id: UUID, title: String, content: String, imageData: Data?, imagesData: [Data], pdfData: Data?, pdfURL: URL?, nextReviewDate: Date, reviewCount: Int, easeFactor: Double, interval: Int, tags: [String]) throws {
        let descriptor = FetchDescriptor<StudyItem>(predicate: #Predicate { $0.id == id })
        if let existingItem = try modelContext.fetch(descriptor).first {
            existingItem.title = title
            existingItem.content = content
            existingItem.imageData = imageData
            existingItem.imagesData = imagesData
            existingItem.pdfData = pdfData
            existingItem.pdfURL = pdfURL
            existingItem.nextReviewDate = nextReviewDate
            existingItem.reviewCount = reviewCount
            existingItem.easeFactor = easeFactor
            existingItem.interval = interval
            existingItem.tags = tags
            try modelContext.save()
        }
    }
    
    func fetchDueItems() throws -> [StudyItemState] {
        let now = Date()
        let descriptor = FetchDescriptor<StudyItem>(predicate: #Predicate { $0.nextReviewDate <= now }, sortBy: [SortDescriptor(\.nextReviewDate)])
        return try modelContext.fetch(descriptor).map { StudyItemState(from: $0) }
    }
    
    func saveReviewSession(itemId: UUID, quality: Int, responseTime: TimeInterval) throws {
        let session = ReviewSession(itemId: itemId, quality: quality, responseTime: responseTime)
        modelContext.insert(session)
        try modelContext.save()
    }
    
    func fetchReviewSessions(itemId: UUID) throws -> [ReviewSessionState] {
        let descriptor = FetchDescriptor<ReviewSession>(predicate: #Predicate { $0.itemId == itemId }, sortBy: [SortDescriptor(\.reviewedAt, order: .reverse)])
        return try modelContext.fetch(descriptor).map { ReviewSessionState(id: $0.id, itemId: $0.itemId, reviewedAt: $0.reviewedAt, quality: $0.quality, responseTime: $0.responseTime) }
    }
}

@MainActor
final class SharedModelContainer {
    static let shared = SharedModelContainer()
    let container: ModelContainer
    private var continuations: [UUID: AsyncStream<[StudyItemState]>.Continuation] = [:]
    
    private init() {
        let schema = Schema([StudyItem.self, ReviewSession.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
            setupChangeObserver()
        } catch {
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))
            container = try! ModelContainer(for: schema, configurations: [config])
            setupChangeObserver()
        }
    }
    
    private func setupChangeObserver() {
        NotificationCenter.default.addObserver(forName: Notification.Name.NSManagedObjectContextDidSave, object: nil, queue: .main) { [weak self] _ in self?.notifyAllSubscribers() }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NSPersistentStoreRemoteChangeNotification"), object: nil, queue: .main) { [weak self] _ in self?.notifyAllSubscribers() }
    }
    
    func createStudyItemsStream() -> AsyncStream<[StudyItemState]> {
        let id = UUID()
        return AsyncStream { [weak self] continuation in
            guard let self = self else { continuation.finish(); return }
            self.continuations[id] = continuation
            continuation.yield(self.fetchItemsSync())
            continuation.onTermination = { [weak self] _ in Task { @MainActor in self?.continuations.removeValue(forKey: id) } }
        }
    }
    
    private func notifyAllSubscribers() {
        let items = fetchItemsSync()
        for continuation in continuations.values { continuation.yield(items) }
    }
    
    private func fetchItemsSync() -> [StudyItemState] {
        let descriptor = FetchDescriptor<StudyItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? container.mainContext.fetch(descriptor).map { StudyItemState(from: $0) }) ?? []
    }
    
    func triggerUpdate() { notifyAllSubscribers() }
}

enum SharedDatabase {
    @MainActor static var shared: DatabaseService { DatabaseService(modelContainer: SharedModelContainer.shared.container) }
}

extension DatabaseClient: DependencyKey {
    static let liveValue = DatabaseClient(
        fetchStudyItems: { try await SharedDatabase.shared.fetchStudyItems() },
        fetchStudyItem: { id in try await SharedDatabase.shared.fetchStudyItem(id: id) },
        saveStudyItem: { item in
            try await SharedDatabase.shared.saveStudyItem(id: item.id, title: item.title, content: item.content, imageData: item.imageData, imagesData: item.imagesData, pdfData: item.pdfData, pdfURL: item.pdfURL, createdAt: item.createdAt, nextReviewDate: item.nextReviewDate, reviewCount: item.reviewCount, easeFactor: item.easeFactor, interval: item.interval, tags: item.tags)
            await MainActor.run { SharedModelContainer.shared.triggerUpdate() }
        },
        deleteStudyItem: { id in
            try await SharedDatabase.shared.deleteStudyItem(id: id)
            await MainActor.run { SharedModelContainer.shared.triggerUpdate() }
        },
        updateStudyItem: { item in
            try await SharedDatabase.shared.updateStudyItem(id: item.id, title: item.title, content: item.content, imageData: item.imageData, imagesData: item.imagesData, pdfData: item.pdfData, pdfURL: item.pdfURL, nextReviewDate: item.nextReviewDate, reviewCount: item.reviewCount, easeFactor: item.easeFactor, interval: item.interval, tags: item.tags)
            await MainActor.run { SharedModelContainer.shared.triggerUpdate() }
        },
        fetchDueItems: { try await SharedDatabase.shared.fetchDueItems() },
        saveReviewSession: { itemId, quality, responseTime in try await SharedDatabase.shared.saveReviewSession(itemId: itemId, quality: quality, responseTime: responseTime) },
        fetchReviewSessions: { itemId in try await SharedDatabase.shared.fetchReviewSessions(itemId: itemId) },
        studyItemsStream: { SharedModelContainer.shared.createStudyItemsStream() }
    )
    
    static let testValue = DatabaseClient(
        fetchStudyItems: { [] }, fetchStudyItem: { _ in nil }, saveStudyItem: { _ in }, deleteStudyItem: { _ in }, updateStudyItem: { _ in }, fetchDueItems: { [] }, saveReviewSession: { _, _, _ in }, fetchReviewSessions: { _ in [] }, studyItemsStream: { AsyncStream { $0.finish() } }
    )
    
    static let previewValue = DatabaseClient(
        fetchStudyItems: { await [StudyItemState(title: "Swift Basics", content: "Swift is a powerful programming language."), StudyItemState(title: "SwiftUI", content: "SwiftUI is a declarative framework.")] },
        fetchStudyItem: { _ in await StudyItemState(title: "Test", content: "Content") },
        saveStudyItem: { _ in }, deleteStudyItem: { _ in }, updateStudyItem: { _ in },
        fetchDueItems: { await [StudyItemState(title: "Due Item", content: "This item is due for review.")] },
        saveReviewSession: { _, _, _ in }, fetchReviewSessions: { _ in [] },
        studyItemsStream: { AsyncStream { $0.yield([StudyItemState(title: "Preview", content: "Content")]) } }
    )
}

extension DependencyValues {
    var databaseClient: DatabaseClient {
        get { self[DatabaseClient.self] }
        set { self[DatabaseClient.self] = newValue }
    }
}
