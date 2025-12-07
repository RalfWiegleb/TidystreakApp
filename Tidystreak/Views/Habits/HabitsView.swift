import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @State private var showingAddHabit = false

    private var activeHabits: [Habit] {
        habits.filter { $0.isActive }
    }

    private var showWarning: Bool {
        activeHabits.count >= 10
    }

    var body: some View {
        NavigationStack {
            List {
                if showWarning {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Many Active Habits")
                                    .font(.headline)
                                Text("Consider focusing on fewer habits for better results.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    ForEach(habits) { habit in
                        HabitRow(habit: habit)
                    }
                    .onDelete(perform: deleteHabits)
                } header: {
                    HStack {
                        Text("Your Habits")
                        Spacer()
                        Text("\(activeHabits.count) Active")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddHabit = true
                    } label: {
                        Label("Add Habit", systemImage: "plus")
                    }
                    .disabled(habits.count >= 20)
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
                    .presentationDetents([.medium, .large])
            }
            .overlay {
                if habits.isEmpty {
                    ContentUnavailableView(
                        "No Habits Yet",
                        systemImage: "list.bullet.circle",
                        description: Text("Add your first habit to get started")
                    )
                }
            }
        }
    }

    private func deleteHabits(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(habits[index])
        }

        // Save immediately to persist deletion
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete habit: \(error)")
        }
    }
}

struct HabitRow: View {
    @Bindable var habit: Habit
    @State private var showingEditSheet = false

    var body: some View {
        HStack(spacing: 12) {
            // Active/Inactive Toggle
            Button {
                habit.isActive.toggle()
            } label: {
                Image(systemName: habit.isActive ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(habit.isActive ? .green : .gray)
                    .font(.system(size: 24))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(habit.isActive ? String(localized: "Active") : String(localized: "Inactive"))
            .accessibilityHint(String(localized: "Double tap to toggle habit activation"))
            .accessibilityValue(habit.name)

            Text(habit.emoji)
                .font(.system(size: 32))
                .opacity(habit.isActive ? 1.0 : 0.5)

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                    .opacity(habit.isActive ? 1.0 : 0.6)

                HStack(spacing: 8) {
                    if habit.currentStreak > 0 {
                        HStack(spacing: 4) {
                            Text("🔥")
                            Text("\(habit.currentStreak)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(String(localized: "Current streak: \(habit.currentStreak) days"))
                    }

                    if !habit.isActive {
                        Text("Inactive")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            if habit.longestStreak > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Best")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(habit.longestStreak)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .opacity(habit.isActive ? 1.0 : 0.6)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(localized: "Best streak: \(habit.longestStreak) days"))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditSheet = true
        }
        .sheet(isPresented: $showingEditSheet) {
            EditHabitView(habit: habit)
                .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    HabitsView()
        .modelContainer(for: [Habit.self, Card.self])
}
