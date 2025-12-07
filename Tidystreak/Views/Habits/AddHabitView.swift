import SwiftUI
import SwiftData
import UserNotifications

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var habits: [Habit]

    @State private var name = ""
    @State private var selectedEmoji = "📝"
    @State private var showLimitAlert = false
    @State private var showDuplicateAlert = false
    @State private var showEmojiPicker = false
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    @FocusState private var isTextFieldFocused: Bool

    let emojis = ["🧹", "🗑️", "📦", "🧺", "📧", "🍽️", "🛏️", "💼", "📚", "👕", "🚗", "💻", "📱", "🧽", "✨", "📝", "🎯", "✅"]
    let colors = ["007AFF", "FF9500", "FF3B30", "34C759", "5856D6", "FF2D55", "5AC8FA"]

    private var canAddMoreHabits: Bool {
        habits.count < 20
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Habit Name", text: $name)
                        .autocorrectionDisabled()
                        .focused($isTextFieldFocused)
                }

                Section("Emoji") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                        ForEach(emojis, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 32))
                                    .frame(width: 50, height: 50)
                                    .background(
                                        selectedEmoji == emoji
                                            ? Color.blue.opacity(0.2)
                                            : Color.clear
                                    )
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }

                        // "Other..." button for custom emoji
                        Button {
                            showEmojiPicker = true
                            isTextFieldFocused = false
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "face.smiling")
                                    .font(.system(size: 20))
                                Text("Other")
                                    .font(.caption2)
                            }
                            .frame(width: 50, height: 50)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Toggle("Daily Reminder", isOn: $reminderEnabled)

                    if reminderEnabled {
                        DatePicker(
                            "Time",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                } header: {
                    Text("Notification")
                } footer: {
                    if reminderEnabled {
                        Text("You'll receive a reminder at this time every day.")
                    }
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addHabit()
                    }
                    .disabled(name.isEmpty || !canAddMoreHabits)
                }
            }
            .alert("Habit Limit Reached", isPresented: $showLimitAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("You've reached the maximum of 20 habits. Consider deactivating some habits before adding new ones.")
            }
            .alert(String(localized: "Duplicate Habit"), isPresented: $showDuplicateAlert) {
                Button(String(localized: "OK")) { }
            } message: {
                Text(String(localized: "A habit with this name already exists. Please choose a different name."))
            }
            .onAppear {
                if !canAddMoreHabits {
                    showLimitAlert = true
                }
            }
            .sheet(isPresented: $showEmojiPicker) {
                EmojiPickerView(selectedEmoji: $selectedEmoji)
            }
        }
    }

    private func addHabit() {
        guard canAddMoreHabits else { return }

        // Check for duplicate name (case-insensitive)
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if habits.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            showDuplicateAlert = true
            return
        }

        let habit = Habit(
            name: name,
            emoji: selectedEmoji,
            colorHex: colors.randomElement() ?? "007AFF",
            isActive: true,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderEnabled ? reminderTime : nil
        )
        modelContext.insert(habit)

        // Explicitly save to ensure persistence
        do {
            try modelContext.save()
        } catch {
            print("Failed to save habit: \(error)")
        }

        // Schedule notification if enabled
        if reminderEnabled {
            scheduleHabitNotification(for: habit)
        }

        dismiss()
    }

    private func scheduleHabitNotification(for habit: Habit) {
        guard let time = habit.reminderTime else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(habit.emoji) Time for: \(habit.name)"
        content.body = "Don't forget to complete this habit today!"
        content.sound = .default

        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.hour, .minute], from: time)

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "habit-\(habit.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule habit notification: \(error)")
            }
        }
    }
}

#Preview {
    AddHabitView()
        .modelContainer(for: [Habit.self, Card.self])
}
