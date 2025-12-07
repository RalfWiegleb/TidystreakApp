import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var emoji: String
    var colorHex: String
    var currentStreak: Int
    var longestStreak: Int
    var lastCompletedDate: Date?
    var createdAt: Date
    var isActive: Bool
    var reminderEnabled: Bool
    var reminderTime: Date?

    init(
        name: String,
        emoji: String = "📝",
        colorHex: String = "007AFF",
        isActive: Bool = true,
        reminderEnabled: Bool = false,
        reminderTime: Date? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastCompletedDate = nil
        self.createdAt = Date()
        self.isActive = isActive
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
    }
}
