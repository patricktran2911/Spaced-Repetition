//
//  StatsFeature.swift
//  Spaced-Repetition
//

import Foundation
import ComposableArchitecture

@Reducer
struct StatsFeature {
    @ObservableState
    struct State: Equatable {
        var totalItems: Int = 0
        var dueToday: Int = 0
        var reviewedToday: Int = 0
        var totalReviews: Int = 0
        var streakDays: Int = 0
        var averageEaseFactor: Double = 2.5
        var itemsByInterval: [IntervalGroup] = []
        var isLoading: Bool = false
        var selectedTip: LearningTip = LearningTip.allCases.randomElement() ?? .activeRecall
        var upcomingReviews: [UpcomingReview] = []
    }
    
    struct IntervalGroup: Equatable, Identifiable {
        let id = UUID()
        let label: String
        let count: Int
        let color: String
    }
    
    struct UpcomingReview: Equatable, Identifiable {
        let id = UUID()
        let dayLabel: String
        let count: Int
    }
    
    enum Action {
        case onAppear
        case onDisappear
        case statsLoaded(Stats)
        case refreshStats
        case nextTipTapped
        case subscribeToItems
        case streamUpdated([StudyItemState])
    }
    
    // CancelID moved to module level
    
    struct Stats: Equatable {
        let totalItems: Int
        let dueToday: Int
        let reviewedToday: Int
        let totalReviews: Int
        let averageEaseFactor: Double
        let itemsByInterval: [IntervalGroup]
        let upcomingReviews: [UpcomingReview]
    }
    
    @Dependency(\.databaseClient) var databaseClient
    @Dependency(\.date.now) var now
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .send(.subscribeToItems)
                
            case .onDisappear:
                return .cancel(id: "statsItemsStream")
                
            case .subscribeToItems:
                _ = now
                return .run { send in
                    let stream = await databaseClient.studyItemsStream()
                    for await items in stream {
                        await send(.streamUpdated(items))
                    }
                }
                .cancellable(id: "statsItemsStream", cancelInFlight: true)
                
            case let .streamUpdated(items):
                state.isLoading = false
                let currentDate = now
                
                let totalItems = items.count
                let dueItems = items.filter { $0.nextReviewDate <= currentDate }
                let dueToday = dueItems.count
                let totalReviews = items.reduce(0) { $0 + $1.reviewCount }
                let reviewedToday = items.filter { $0.reviewCount > 0 && $0.nextReviewDate > currentDate }.count
                let avgEase = items.isEmpty ? 2.5 : items.reduce(0.0) { $0 + $1.easeFactor } / Double(items.count)
                let intervalGroups = calculateIntervalGroups(items: items)
                let upcomingReviews = calculateUpcomingReviews(items: items, from: currentDate)
                
                state.totalItems = totalItems
                state.dueToday = dueToday
                state.reviewedToday = reviewedToday
                state.totalReviews = totalReviews
                state.averageEaseFactor = avgEase
                state.itemsByInterval = intervalGroups
                state.upcomingReviews = upcomingReviews
                return .none
                
            case let .statsLoaded(stats):
                state.isLoading = false
                state.totalItems = stats.totalItems
                state.dueToday = stats.dueToday
                state.reviewedToday = stats.reviewedToday
                state.totalReviews = stats.totalReviews
                state.averageEaseFactor = stats.averageEaseFactor
                state.itemsByInterval = stats.itemsByInterval
                state.upcomingReviews = stats.upcomingReviews
                return .none
                
            case .refreshStats:
                return .send(.subscribeToItems)
                
            case .nextTipTapped:
                let allTips = LearningTip.allCases
                if let currentIndex = allTips.firstIndex(of: state.selectedTip) {
                    let nextIndex = (currentIndex + 1) % allTips.count
                    state.selectedTip = allTips[nextIndex]
                }
                return .none
            }
        }
    }
    
    private func calculateIntervalGroups(items: [StudyItemState]) -> [IntervalGroup] {
        var newItems = 0
        var learning = 0
        var young = 0
        var mature = 0
        
        for item in items {
            switch item.interval {
            case 0: newItems += 1
            case 1...6: learning += 1
            case 7...21: young += 1
            default: mature += 1
            }
        }
        
        return [
            IntervalGroup(label: "New", count: newItems, color: "blue"),
            IntervalGroup(label: "Learning", count: learning, color: "orange"),
            IntervalGroup(label: "Young", count: young, color: "yellow"),
            IntervalGroup(label: "Mature", count: mature, color: "green")
        ]
    }
    
    private func calculateUpcomingReviews(items: [StudyItemState], from date: Date) -> [UpcomingReview] {
        let calendar = Calendar.current
        var reviews: [UpcomingReview] = []
        
        for dayOffset in 0..<7 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: date) else { continue }
            let startOfDay = calendar.startOfDay(for: targetDate)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }
            
            let count = items.filter { $0.nextReviewDate >= startOfDay && $0.nextReviewDate < endOfDay }.count
            
            let dayLabel: String
            if dayOffset == 0 { dayLabel = "Today" }
            else if dayOffset == 1 { dayLabel = "Tomorrow" }
            else {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEE"
                dayLabel = formatter.string(from: targetDate)
            }
            
            reviews.append(UpcomingReview(dayLabel: dayLabel, count: count))
        }
        
        return reviews
    }
}

enum LearningTip: String, CaseIterable, Equatable {
    case activeRecall, spacedRepetition, sleep, context, consistency, optimalTime
    
    var title: String {
        switch self {
        case .activeRecall: return "Active Recall"
        case .spacedRepetition: return "Spaced Repetition"
        case .sleep: return "Sleep & Memory"
        case .context: return "Varied Context"
        case .consistency: return "Consistency"
        case .optimalTime: return "Optimal Review Time"
        }
    }
    
    var description: String {
        switch self {
        case .activeRecall: return "Test yourself rather than passively rereading. Active retrieval strengthens memory pathways."
        case .spacedRepetition: return "Review at increasing intervals (1→3→7→14 days). This leverages the spacing effect."
        case .sleep: return "Review before sleep for better memory consolidation. Your brain processes memories during sleep."
        case .context: return "Review in different contexts and environments for stronger, more flexible memories."
        case .consistency: return "Don't cram! Consistent daily practice beats occasional marathon sessions."
        case .optimalTime: return "Afternoon (4-9 PM) is optimal for long-term memory. Morning is good for immediate recall."
        }
    }
    
    var icon: String {
        switch self {
        case .activeRecall: return "brain.head.profile"
        case .spacedRepetition: return "clock.arrow.circlepath"
        case .sleep: return "moon.stars.fill"
        case .context: return "map.fill"
        case .consistency: return "calendar"
        case .optimalTime: return "sun.max.fill"
        }
    }
}
