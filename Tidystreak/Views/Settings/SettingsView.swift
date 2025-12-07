import SwiftUI
import UserNotifications

struct SettingsView: View {
    @State private var notificationsEnabled = false
    @State private var isCheckingStatus = true
    @State private var showingFAQ = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Daily Reminders", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            handleNotificationToggle(newValue)
                        }
                } header: {
                    Text("Notifications")
                } footer: {
                    if notificationsEnabled {
                        Text("You'll receive reminders at 8:00 AM and 8:00 PM daily.")
                    } else {
                        Text("Enable notifications to get daily reminders.")
                    }
                }

                Section("About") {
                    Button {
                        showingFAQ = true
                    } label: {
                        HStack {
                            Label("How It Works", systemImage: "questionmark.circle")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .task {
                await checkNotificationStatus()
            }
            .sheet(isPresented: $showingFAQ) {
                FAQView()
            }
        }
    }

    private func checkNotificationStatus() async {
        let status = await NotificationManager.shared.checkAuthorizationStatus()
        await MainActor.run {
            notificationsEnabled = (status == .authorized)
            isCheckingStatus = false
        }
    }

    private func handleNotificationToggle(_ enabled: Bool) {
        Task {
            if enabled {
                let granted = await NotificationManager.shared.requestAuthorization()
                await MainActor.run {
                    notificationsEnabled = granted
                }

                if granted {
                    NotificationManager.shared.scheduleNotifications()
                }
            } else {
                // Only remove daily notifications, preserve timer notifications
                UNUserNotificationCenter.current().removePendingNotificationRequests(
                    withIdentifiers: ["morning", "evening"]
                )
            }
        }
    }
}

#Preview {
    SettingsView()
}
