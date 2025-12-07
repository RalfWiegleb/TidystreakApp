import SwiftUI
import SwiftData

@main
struct TidystreakApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var modelContainer: ModelContainer?

    init() {
        // Initialize model container
        do {
            let container = try ModelContainer(for: Habit.self, Card.self)
            _modelContainer = State(initialValue: container)
        } catch {
            print("Failed to initialize ModelContainer: \(error)")
        }

        // Request notification permission on first launch
        Task {
            let granted = await NotificationManager.shared.requestAuthorization()
            if granted {
                NotificationManager.shared.scheduleNotifications()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .background {
                        updateSmartNotifications()
                    }
                }
        }
        .modelContainer(for: [Habit.self, Card.self])
    }

    private func updateSmartNotifications() {
        guard let container = modelContainer else { return }

        Task { @MainActor in
            let context = container.mainContext

            // Fetch active habits count
            let habitsDescriptor = FetchDescriptor<Habit>()
            let allHabits = (try? context.fetch(habitsDescriptor)) ?? []
            let activeHabitsCount = allHabits.filter { $0.isActive }.count

            // Fetch open cards count
            let cardsDescriptor = FetchDescriptor<Card>()
            let allCards = (try? context.fetch(cardsDescriptor)) ?? []
            let openCardsCount = allCards.filter {
                $0.isFromToday && $0.status != .done
            }.count

            // Schedule smart notifications
            NotificationManager.shared.scheduleSmartNotifications(
                activeHabitsCount: activeHabitsCount,
                openCardsCount: openCardsCount
            )
        }
    }
}
