import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UserNotifications
import Combine

struct BoardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \Card.createdAt) private var allCards: [Card]
    @Query private var habits: [Habit]

    @State private var showingGenerateCards = false
    @State private var showWIPLimitAlert = false

    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    private var todayCards: [Card] {
        allCards.filter { $0.isFromToday }
    }

    private var todoCards: [Card] {
        todayCards.filter { $0.status == .todo }
    }

    private var doingCards: [Card] {
        todayCards.filter { $0.status == .doing }
    }

    private var doneCards: [Card] {
        todayCards.filter { $0.status == .done }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with date and WIP indicator
                VStack(spacing: 8) {
                    Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        Text("WIP:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(doingCards.count)/2")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(doingCards.count > 2 ? .red : .green)
                    }
                }
                .padding()

                // Kanban Board - Adaptive Layout
                if isCompact {
                    // Portrait: Vertical stacked layout
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 16) {
                            KanbanColumn(
                                title: "TODO",
                                cards: todoCards,
                                color: .gray,
                                allCards: todayCards,
                                onDrop: { card in moveCard(card, to: .todo) },
                                onMove: moveCard,
                                isCompact: true
                            )

                            KanbanColumn(
                                title: "DOING",
                                cards: doingCards,
                                color: .blue,
                                allCards: todayCards,
                                onDrop: { card in moveCard(card, to: .doing) },
                                onMove: moveCard,
                                isCompact: true
                            )

                            KanbanColumn(
                                title: "DONE",
                                cards: doneCards,
                                color: .green,
                                allCards: todayCards,
                                onDrop: { card in moveCard(card, to: .done) },
                                onMove: moveCard,
                                isCompact: true
                            )
                        }
                        .padding()
                    }
                } else {
                    // Landscape: Horizontal scroll layout
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 16) {
                            KanbanColumn(
                                title: "TODO",
                                cards: todoCards,
                                color: .gray,
                                allCards: todayCards,
                                onDrop: { card in moveCard(card, to: .todo) },
                                onMove: moveCard,
                                isCompact: false
                            )

                            KanbanColumn(
                                title: "DOING",
                                cards: doingCards,
                                color: .blue,
                                allCards: todayCards,
                                onDrop: { card in moveCard(card, to: .doing) },
                                onMove: moveCard,
                                isCompact: false
                            )

                            KanbanColumn(
                                title: "DONE",
                                cards: doneCards,
                                color: .green,
                                allCards: todayCards,
                                onDrop: { card in moveCard(card, to: .done) },
                                onMove: moveCard,
                                isCompact: false
                            )
                        }
                        .padding()
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .navigationTitle("Tidystreak")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingGenerateCards = true
                    } label: {
                        Label("New Day", systemImage: "sunrise")
                    }
                    .accessibilityHint(String(localized: "Generate today's cards from active habits"))
                }
            }
            .sheet(isPresented: $showingGenerateCards) {
                GenerateCardsView(habits: habits)
            }
            .alert(String(localized: "WIP Limit Reached"), isPresented: $showWIPLimitAlert) {
                Button(String(localized: "OK")) { }
            } message: {
                Text(String(localized: "You can only have 2 tasks in progress at once. Complete or move a task first."))
            }
        }
    }

    private func moveCard(_ card: Card, to newStatus: CardStatus) {
        // Check WIP limit for DOING column
        if newStatus == .doing && doingCards.count >= 2 && card.status != .doing {
            // Don't allow more than 2 in DOING
            showWIPLimitAlert = true
            // Haptic feedback
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            #endif
            return
        }

        let previousStatus = card.status
        card.status = newStatus

        if newStatus == .doing && card.movedToDoingAt == nil {
            card.movedToDoingAt = Date()
        }

        if newStatus == .done && card.completedAt == nil {
            card.completedAt = Date()
            updateStreak(for: card)
        }

        // Clear timer when card leaves DOING
        if previousStatus == .doing && newStatus != .doing {
            // Store card ID before clearing state to prevent race condition
            let cardID = card.id.uuidString

            // Clear card state synchronously
            card.timerDuration = nil
            card.timerStartedAt = nil
            card.movedToDoingAt = nil

            // Cancel any pending timer notification asynchronously
            Task {
                UNUserNotificationCenter.current().removePendingNotificationRequests(
                    withIdentifiers: ["card-timer-\(cardID)"]
                )
            }
        }
    }

    private func updateStreak(for card: Card) {
        guard let habit = habits.first(where: { $0.id == card.habitID }) else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastCompleted = habit.lastCompletedDate {
            let lastCompletedDay = calendar.startOfDay(for: lastCompleted)
            let daysBetween = calendar.dateComponents([.day], from: lastCompletedDay, to: today).day ?? 0

            if daysBetween == 1 {
                // Consecutive day
                habit.currentStreak += 1
            } else if daysBetween > 1 {
                // Streak broken
                habit.currentStreak = 1
            }
            // If daysBetween == 0, same day, don't increment
        } else {
            // First time completing
            habit.currentStreak = 1
        }

        habit.lastCompletedDate = Date()
        habit.longestStreak = max(habit.longestStreak, habit.currentStreak)
    }

}

struct KanbanColumn: View {
    let title: String
    let cards: [Card]
    let color: Color
    let allCards: [Card]
    let onDrop: (Card) -> Void
    let onMove: (Card, CardStatus) -> Void
    let isCompact: Bool

    private var emptyStateIcon: String {
        switch title {
        case "TODO": return "tray"
        case "DOING": return "figure.run"
        case "DONE": return "checkmark.circle"
        default: return "tray"
        }
    }

    private var emptyStateText: String {
        switch title {
        case "TODO": return String(localized: "No tasks yet.\nDrag cards here to start.")
        case "DOING": return String(localized: "Nothing in progress.\nDrag a task here to begin.")
        case "DONE": return String(localized: "No completed tasks.\nFinish a task to see it here!")
        default: return String(localized: "Empty")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(cards.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .cornerRadius(8)
            }

            if cards.isEmpty {
                // Empty State
                VStack(spacing: 12) {
                    Image(systemName: emptyStateIcon)
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary.opacity(0.5))

                    Text(emptyStateText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 8) {
                    ForEach(cards) { card in
                        DraggableCardView(card: card, onMove: onMove, columnTitle: title)
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: isCompact ? .infinity : .infinity)
        .frame(minWidth: isCompact ? 0 : 350)
        .frame(minHeight: isCompact ? 200 : 300)
        .frame(maxHeight: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onDrop(of: [.text], isTargeted: nil) { providers in
            providers.first?.loadItem(forTypeIdentifier: "public.text", options: nil) { data, error in
                guard let data = data as? Data,
                      let idString = String(data: data, encoding: .utf8),
                      let id = UUID(uuidString: idString),
                      let card = allCards.first(where: { $0.id == id }) else {
                    return
                }

                DispatchQueue.main.async {
                    onDrop(card)
                }
            }
            return true
        }
    }
}

/// Wrapper view that handles drag gestures and state
struct DraggableCardView: View {
    @Bindable var card: Card
    let onMove: (Card, CardStatus) -> Void
    let columnTitle: String
    @State private var isDragging = false

    var body: some View {
        CardView(card: card, isDragging: isDragging)
            .onDrag {
                isDragging = true
                return NSItemProvider(object: card.id.uuidString as NSString)
            }
            .onChange(of: card.status) { _, _ in
                // Reset dragging state when card moves
                isDragging = false
            }
            .accessibilityLabel("\(card.emoji) \(card.habitName)")
            .accessibilityHint(String(localized: "Currently in \(columnTitle). Use actions to move."))
            .accessibilityActions {
                if card.status != .todo {
                    Button(String(localized: "Move to TODO")) {
                        onMove(card, .todo)
                    }
                }
                if card.status != .doing {
                    Button(String(localized: "Move to DOING")) {
                        onMove(card, .doing)
                    }
                }
                if card.status != .done {
                    Button(String(localized: "Move to DONE")) {
                        onMove(card, .done)
                    }
                }
            }
    }
}

struct CardView: View {
    @Bindable var card: Card
    var isDragging: Bool = false
    @State private var showTimerPicker = false
    @State private var timeRemaining: TimeInterval = 0
    @State private var timerActive = false
    @State private var showTimerConfirmation = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text(card.emoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 4) {
                    Text(card.habitName)
                        .font(.body)
                        .strikethrough(card.status == .done, color: .green)
                        .foregroundStyle(card.status == .done ? .secondary : .primary)

                    if card.timerDuration != nil && card.status == .doing {
                        if timeRemaining > 0 {
                            Text("⏱️ \(formattedTimeRemaining)")
                                .font(.caption)
                                .foregroundStyle(timeRemaining < 300 ? .red : .secondary)
                                .monospacedDigit()
                        } else if timerActive {
                            Text("⏱️ Time's up!")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                Spacer()

                // Checkmark for done cards
                if card.status == .done {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 20))
                }
            }

            // Timer buttons for DOING cards
            if card.status == .doing && card.timerDuration == nil {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Set timer:"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach([15, 30, 60, 90], id: \.self) { minutes in
                            Button {
                                setTimer(minutes: minutes)
                            } label: {
                                Text("\(minutes)m")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(String(localized: "Set timer for \(minutes) minutes"))
                        }
                    }
                }
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(isDragging ? 0.2 : 0.08), radius: isDragging ? 8 : 4, x: 0, y: isDragging ? 4 : 2)
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        .onReceive(timer) { _ in
            updateTimeRemaining()
        }
        .onAppear {
            updateTimeRemaining()
        }
        .overlay(alignment: .top) {
            if showTimerConfirmation {
                Text("⏱️ Timer set for \(card.timerDuration ?? 0) min")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.green)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .offset(y: -40)
            }
        }
    }

    private var cardBackground: some View {
        Group {
            if card.status == .done {
                // Done cards: subtle green background
                Color.green.opacity(0.1)
            } else {
                // Active cards: habit color
                Color(hex: card.colorHex).opacity(0.15)
            }
        }
    }

    private var formattedTimeRemaining: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func updateTimeRemaining() {
        guard let endDate = card.timerEndDate else {
            timeRemaining = 0
            timerActive = false
            return
        }

        let remaining = endDate.timeIntervalSinceNow
        if remaining > 0 {
            timeRemaining = remaining
            timerActive = true
        } else {
            timeRemaining = 0
            timerActive = true
        }
    }

    private func setTimer(minutes: Int) {
        card.timerDuration = minutes
        card.timerStartedAt = Date()
        updateTimeRemaining()
        scheduleTimerNotification(for: card, minutes: minutes)

        // Show confirmation toast
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showTimerConfirmation = true
        }

        // Hide toast after 2 seconds
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation {
                showTimerConfirmation = false
            }
        }

        // Haptic feedback
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }

    private func scheduleTimerNotification(for card: Card, minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "\(card.emoji) \(card.habitName)"
        content.body = String(localized: "Time's up! Don't forget to finish this task.")
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(minutes * 60),
            repeats: false
        )

        let identifier = "card-timer-\(card.id.uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule timer notification: \(error)")
            } else {
                print("✅ Timer notification scheduled for \(minutes) min (ID: \(identifier))")
            }
        }
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    BoardView()
        .modelContainer(for: [Habit.self, Card.self])
}
