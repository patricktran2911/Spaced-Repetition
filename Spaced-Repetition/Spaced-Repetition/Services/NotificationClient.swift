//
//  NotificationClient.swift
//  Spaced-Repetition
//
//  Created by Patrick Tran on 1/20/26.
//

import Foundation
import ComposableArchitecture
import UserNotifications

struct NotificationClient: Sendable {
    var requestAuthorization: @Sendable () async throws -> Bool
    var scheduleReviewReminder: @Sendable (_ date: Date, _ itemCount: Int) async throws -> Void
    var scheduleDailyReminder: @Sendable (_ hour: Int, _ minute: Int) async throws -> Void
    var cancelAllNotifications: @Sendable () async -> Void
    var getPendingNotificationCount: @Sendable () async -> Int
    var getAuthorizationStatus: @Sendable () async -> UNAuthorizationStatus
}

extension NotificationClient: DependencyKey {
    static let liveValue = NotificationClient(
        requestAuthorization: {
            let center = UNUserNotificationCenter.current()
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        },
        scheduleReviewReminder: { date, itemCount in
            let center = UNUserNotificationCenter.current()
            
            let content = UNMutableNotificationContent()
            content.title = "Time to Review! 📚"
            content.body = itemCount == 1 
                ? "You have 1 item ready for review"
                : "You have \(itemCount) items ready for review"
            content.sound = .default
            content.badge = NSNumber(value: itemCount)
            content.categoryIdentifier = "REVIEW_REMINDER"
            
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "review-\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            
            try await center.add(request)
        },
        scheduleDailyReminder: { hour, minute in
            let center = UNUserNotificationCenter.current()
            
            // Remove existing daily reminders first
            let pendingRequests = await center.pendingNotificationRequests()
            let dailyIds = pendingRequests.filter { $0.identifier.hasPrefix("daily-") }.map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: dailyIds)
            
            let content = UNMutableNotificationContent()
            content.title = "Review Time! 🧠"
            content.body = "Don't forget to review your study items today. Consistent practice builds lasting memory!"
            content.sound = .default
            content.categoryIdentifier = "DAILY_REMINDER"
            
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: "daily-reminder",
                content: content,
                trigger: trigger
            )
            
            try await center.add(request)
        },
        cancelAllNotifications: {
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests()
            try? await center.setBadgeCount(0)
        },
        getPendingNotificationCount: {
            let center = UNUserNotificationCenter.current()
            let requests = await center.pendingNotificationRequests()
            return requests.count
        },
        getAuthorizationStatus: {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            return settings.authorizationStatus
        }
    )
    
    static let testValue = NotificationClient(
        requestAuthorization: { true },
        scheduleReviewReminder: { _, _ in },
        scheduleDailyReminder: { _, _ in },
        cancelAllNotifications: { },
        getPendingNotificationCount: { 0 },
        getAuthorizationStatus: { .authorized }
    )
    
    static let previewValue = testValue
}

extension DependencyValues {
    var notificationClient: NotificationClient {
        get { self[NotificationClient.self] }
        set { self[NotificationClient.self] = newValue }
    }
}