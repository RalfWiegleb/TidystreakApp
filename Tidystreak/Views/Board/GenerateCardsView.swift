import SwiftUI
import SwiftData

struct GenerateCardsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Card.createdAt) private var allCards: [Card]

    let habits: [Habit]
    @State private var selectedHabits: Set<UUID> = []

    private var activeHabits: [Habit] {
        habits.filter { $0.isActive }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if activeHabits.isEmpty {
                    ContentUnavailableView(
                        "No Active Habits",
                        systemImage: "list.bullet.circle",
                        description: Text("Activate some habits first to generate cards")
                    )
                } else {
                    List {
                        Section {
                            ForEach(activeHabits) { habit in
                                HabitSelectionRow(
                                    habit: habit,
                                    isSelected: selectedHabits.contains(habit.id)
                                ) {
                                    toggleSelection(for: habit)
                                }
                            }
                        } header: {
                            HStack {
                                Text("Select Habits for Today")
                                Spacer()
                                Button(selectedHabits.count == activeHabits.count ? "Deselect All" : "Select All") {
                                    toggleSelectAll()
                                }
                                .font(.caption)
                                .textCase(.none)
                            }
                        } footer: {
                            Text("\(selectedHabits.count) of \(activeHabits.count) habits selected")
                        }
                    }
                }
            }
            .navigationTitle("New Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        generateCards()
                    }
                    .disabled(selectedHabits.isEmpty)
                }
            }
            .onAppear {
                // Pre-select all active habits
                selectedHabits = Set(activeHabits.map { $0.id })
            }
        }
    }

    private func toggleSelection(for habit: Habit) {
        if selectedHabits.contains(habit.id) {
            selectedHabits.remove(habit.id)
        } else {
            selectedHabits.insert(habit.id)
        }
    }

    private func toggleSelectAll() {
        if selectedHabits.count == activeHabits.count {
            selectedHabits.removeAll()
        } else {
            selectedHabits = Set(activeHabits.map { $0.id })
        }
    }

    private func generateCards() {
        // Delete only today's cards
        let todayCards = allCards.filter { $0.isFromToday }
        for card in todayCards {
            modelContext.delete(card)
        }

        // Save deletion immediately to prevent race condition
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete old cards: \(error)")
            dismiss()
            return
        }

        // Create new cards from selected habits only
        let selectedHabitsList = activeHabits.filter { selectedHabits.contains($0.id) }
        for habit in selectedHabitsList {
            let card = Card(
                habitID: habit.id,
                habitName: habit.name,
                emoji: habit.emoji,
                colorHex: habit.colorHex
            )
            modelContext.insert(card)
        }

        // Save new cards
        do {
            try modelContext.save()
        } catch {
            print("Failed to save new cards: \(error)")
        }

        dismiss()
    }
}

struct HabitSelectionRow: View {
    let habit: Habit
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .gray)
                    .font(.system(size: 24))
                    .accessibilityHidden(true)

                Text(habit.emoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if habit.currentStreak > 0 {
                        HStack(spacing: 4) {
                            Text("🔥")
                            Text("\(habit.currentStreak) day streak")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(habit.emoji) \(habit.name)")
        .accessibilityValue(isSelected ? String(localized: "Selected") : String(localized: "Not selected"))
        .accessibilityHint(String(localized: "Double tap to toggle selection"))
    }
}

#Preview {
    GenerateCardsView(habits: [])
        .modelContainer(for: [Habit.self, Card.self])
}
