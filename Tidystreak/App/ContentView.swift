import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            BoardView()
                .tabItem {
                    Label(String(localized: "Board"), systemImage: "tablecells.fill")
                }

            HabitsView()
                .tabItem {
                    Label(String(localized: "Habits"), systemImage: "list.bullet.circle")
                }

            SettingsView()
                .tabItem {
                    Label(String(localized: "Settings"), systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
}
