import Foundation
import UserNotifications
import SwiftData

@MainActor
class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    nonisolated func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }

    func scheduleNotifications() {
        // Remove only daily notification requests, preserve timer notifications
        removeDailyNotifications()

        // Schedule both notifications (they will check context at trigger time)
        scheduleDailyNotification(
            id: "morning",
            title: String(localized: "Good Morning! ☀️"),
            body: String(localized: "Your board is ready for today. Let's get things done!"),
            hour: 8,
            minute: 0
        )

        scheduleDailyNotification(
            id: "evening",
            title: String(localized: "Time to wrap up! 🌙"),
            body: String(localized: "Don't forget to complete your cards and keep your streak alive!"),
            hour: 20,
            minute: 0
        )
    }

    /// Schedule smart notifications based on current app state
    func scheduleSmartNotifications(activeHabitsCount: Int, openCardsCount: Int) {
        // Remove only daily notification requests, preserve timer notifications
        removeDailyNotifications()

        // Morning notification - only if there are active habits
        if activeHabitsCount > 0 {
            let body = activeHabitsCount == 1
                ? String(localized: "You have 1 active habit. Time to generate today's card!")
                : String(localized: "You have \(activeHabitsCount) active habits. Time to generate today's cards!")

            scheduleDailyNotification(
                id: "morning",
                title: String(localized: "Good Morning! ☀️"),
                body: body,
                hour: 8,
                minute: 0
            )
        }

        // Evening notification - only if there are open cards
        if openCardsCount > 0 {
            let body = openCardsCount == 1
                ? String(localized: "You still have 1 open card. Don't forget to complete it!")
                : String(localized: "You still have \(openCardsCount) open cards. Keep your streak alive!")

            scheduleDailyNotification(
                id: "evening",
                title: String(localized: "Time to wrap up! 🌙"),
                body: body,
                hour: 20,
                minute: 0
            )
        }
    }

    private func scheduleDailyNotification(
        id: String,
        title: String,
        body: String,
        hour: Int,
        minute: Int
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    nonisolated func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    /// Remove only daily notifications (morning/evening), preserve timer notifications
    private func removeDailyNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["morning", "evening"]
        )
    }
}
