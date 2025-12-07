import SwiftUI
import SwiftData
import UserNotifications

struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var habit: Habit
    @Query private var habits: [Habit]

    @State private var name: String
    @State private var selectedEmoji: String
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var showDuplicateAlert = false
    @State private var showEmojiPicker = false
    @FocusState private var isTextFieldFocused: Bool

    let emojis = ["🧹", "🗑️", "📦", "🧺", "📧", "🍽️", "🛏️", "💼", "📚", "👕", "🚗", "💻", "📱", "🧽", "✨", "📝", "🎯", "✅"]

    init(habit: Habit) {
        self.habit = habit
        _name = State(initialValue: habit.name)
        _selectedEmoji = State(initialValue: habit.emoji)
        _reminderEnabled = State(initialValue: habit.reminderEnabled)
        _reminderTime = State(initialValue: habit.reminderTime ?? Date())
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
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .alert(String(localized: "Duplicate Habit"), isPresented: $showDuplicateAlert) {
                Button(String(localized: "OK")) { }
            } message: {
                Text(String(localized: "A habit with this name already exists. Please choose a different name."))
            }
            .sheet(isPresented: $showEmojiPicker) {
                EmojiPickerView(selectedEmoji: $selectedEmoji)
            }
        }
    }

    private func saveChanges() {
        // Check for duplicate name (case-insensitive, excluding current habit)
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if habits.contains(where: { $0.id != habit.id && $0.name.lowercased() == trimmedName.lowercased() }) {
            showDuplicateAlert = true
            return
        }

        // Update habit
        habit.name = trimmedName
        habit.emoji = selectedEmoji

        // Handle reminder changes
        let reminderChanged = habit.reminderEnabled != reminderEnabled || habit.reminderTime != reminderTime

        habit.reminderEnabled = reminderEnabled
        habit.reminderTime = reminderEnabled ? reminderTime : nil

        // Update notifications if reminder settings changed
        if reminderChanged {
            // Remove old notification
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: ["habit-\(habit.id.uuidString)"]
            )

            // Schedule new notification if enabled
            if reminderEnabled {
                scheduleHabitNotification(for: habit)
            }
        }

        dismiss()
    }

    private func scheduleHabitNotification(for habit: Habit) {
        guard let time = habit.reminderTime else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(habit.emoji) Time for: \(habit.name)"
        content.body = String(localized: "Don't forget to complete this habit today!")
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
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Habit.self, configurations: config)
        let habit = Habit(name: "Test Habit", emoji: "🧹")
        return EditHabitView(habit: habit)
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
