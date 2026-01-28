//
//  ReviewSession.swift
//  Spaced-Repetition
//
//  Created by Patrick Tran on 1/20/26.
//

import Foundation
import SwiftData

@Model
final class ReviewSession {
    @Attribute(.unique) var id: UUID
    var itemId: UUID
    var reviewedAt: Date
    var quality: Int
    var responseTime: TimeInterval
    
    init(
        id: UUID = UUID(),
        itemId: UUID,
        reviewedAt: Date = Date(),
        quality: Int,
        responseTime: TimeInterval = 0
    ) {
        self.id = id
        self.itemId = itemId
        self.reviewedAt = reviewedAt
        self.quality = quality
        self.responseTime = responseTime
    }
}
