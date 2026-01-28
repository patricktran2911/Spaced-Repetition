//
//  AppFeature.swift
//  Spaced-Repetition
//

import Foundation
import ComposableArchitecture

@Reducer 
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .items
        var studyItems = StudyItemsFeature.State()
        var lectureReview = LectureReviewFeature.State()
        var stats = StatsFeature.State()
        var notificationsEnabled: Bool = false
        var dailyReminderHour: Int = 18
        var dailyReminderMinute: Int = 0
        
        enum Tab: String, CaseIterable, Equatable {
            case items = "Library"
            case review = "Review"           
            case stats = "Stats"
            
            var icon: String {
                switch self {
                case .items: return "books.vertical.fill"
                case .review: return "book.fill"
                case .stats: return "chart.bar.fill"
                }
            }
        }
    }
    
    enum Action: BindableAction, Sendable {
        case binding(BindingAction<State>)
        case studyItems(StudyItemsFeature.Action)
        case lectureReview(LectureReviewFeature.Action)
        case stats(StatsFeature.Action)
        case onAppear
        case notificationAuthorizationReceived(Bool)
        case scheduleDailyReminder
        case checkDueItemsAndNotify
    }
    
    @Dependency(\.notificationClient) var notificationClient
    @Dependency(\.databaseClient) var databaseClient
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Scope(state: \.studyItems, action: \.studyItems) {
            StudyItemsFeature()
        }
        
        Scope(state: \.lectureReview, action: \.lectureReview) {
            LectureReviewFeature()
        }
        
        Scope(state: \.stats, action: \.stats) {
            StatsFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .onAppear:
                return .run { send in
                    let authorized = (try? await notificationClient.requestAuthorization()) ?? false
                    await send(.notificationAuthorizationReceived(authorized))
                    await send(.checkDueItemsAndNotify)
                }
                
            case let .notificationAuthorizationReceived(authorized):
                state.notificationsEnabled = authorized
                if authorized { return .send(.scheduleDailyReminder) }
                return .none
                
            case .scheduleDailyReminder:
                let hour = state.dailyReminderHour
                let minute = state.dailyReminderMinute
                return .run { _ in try? await notificationClient.scheduleDailyReminder(hour, minute) }
                
            case .checkDueItemsAndNotify:
                return .run { _ in
                    let dueItems = try await databaseClient.fetchDueItems()
                    if !dueItems.isEmpty {
                        let notifyDate = Date().addingTimeInterval(3600)
                        try? await notificationClient.scheduleReviewReminder(notifyDate, dueItems.count)
                    }
                }
                
            case .studyItems, .lectureReview, .stats:
                return .none
            }
        }
    }
}
