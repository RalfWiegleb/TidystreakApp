import Foundation
import SwiftData

enum CardStatus: String, Codable {
    case todo = "TODO"
    case doing = "DOING"
    case done = "DONE"
}

@Model
final class Card {
    var id: UUID
    var habitID: UUID
    var habitName: String
    var emoji: String
    var colorHex: String
    var status: CardStatus
    var createdAt: Date
    var movedToDoingAt: Date?
    var completedAt: Date?
    var timerDuration: Int? // in minutes (15, 30, 60, 90)
    var timerStartedAt: Date? // when the timer button was pressed

    init(
        habitID: UUID,
        habitName: String,
        emoji: String,
        colorHex: String,
        status: CardStatus = .todo
    ) {
        self.id = UUID()
        self.habitID = habitID
        self.habitName = habitName
        self.emoji = emoji
        self.colorHex = colorHex
        self.status = status
        self.createdAt = Date()
        self.timerDuration = nil
    }

    var isFromToday: Bool {
        Calendar.current.isDateInToday(createdAt)
    }

    var timerEndDate: Date? {
        guard let timerStartedAt = timerStartedAt,
              let duration = timerDuration else {
            return nil
        }
        return timerStartedAt.addingTimeInterval(TimeInterval(duration * 60))
    }
}
