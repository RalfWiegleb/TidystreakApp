import SwiftUI

struct FAQView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // App Description
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.title)
                                .foregroundStyle(.blue)
                            Text(String(localized: "What is Tidystreak?"))
                                .font(.title2)
                                .fontWeight(.semibold)
                        }

                        Text(String(localized: "Tidystreak combines habit tracking with a Kanban board to help you turn chaos into order. Track your daily habits, visualize your workflow, and build streaks!"))
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    Divider()

                    // FAQ Items
                    VStack(alignment: .leading, spacing: 20) {
                        Text(String(localized: "Frequently Asked Questions"))
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        FAQItem(
                            icon: "plus.circle",
                            question: String(localized: "How do I get started?"),
                            answer: String(localized: "1. Go to the Habits tab and create your recurring tasks (max 20)\n2. Activate the habits you want to focus on\n3. Press 'New Day' in the Board tab to generate today's cards\n4. Drag cards through TODO → DOING → DONE")
                        )

                        FAQItem(
                            icon: "flame",
                            question: String(localized: "How do streaks work?"),
                            answer: String(localized: "Streaks count only when a card completes the full workflow (TODO → DOING → DONE). Complete a habit every day to maintain your streak. Your longest streak is saved automatically!")
                        )

                        FAQItem(
                            icon: "figure.run",
                            question: String(localized: "What is the WIP Limit?"),
                            answer: String(localized: "WIP (Work In Progress) Limit prevents multitasking. You can only have 2 cards in DOING at once. This helps you focus and finish tasks instead of starting too many things.")
                        )

                        FAQItem(
                            icon: "timer",
                            question: String(localized: "How does the DOING timer work?"),
                            answer: String(localized: "When you move a card to DOING, you can set a timer (15/30/60/90 min). You'll get a notification when time is up to remind you to finish the task.")
                        )

                        FAQItem(
                            icon: "bell",
                            question: String(localized: "What notifications will I receive?"),
                            answer: String(localized: "• Daily reminders at 8:00 AM and 8:00 PM\n• Per-habit reminders (optional, set in each habit)\n• Timer notifications when DOING timers expire")
                        )

                        FAQItem(
                            icon: "checkmark.circle",
                            question: String(localized: "How many habits should I track?"),
                            answer: String(localized: "We recommend 5-10 active habits for best results. The app shows a warning at 10+ active habits to prevent overwhelm. You can deactivate habits without deleting them.")
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("How It Works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FAQItem: View {
    let icon: String
    let question: String
    let answer: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                Text(question)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text(answer)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    FAQView()
}
