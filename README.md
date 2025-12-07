# Tidystreak

Eine iOS App die Habit Tracking mit einem Kanban Board kombiniert, um Chaos in Ordnung zu verwandeln.

## Konzept

**Tidystreak** löst ein häufiges Problem: Wir starten viele Dinge, aber beenden sie nicht. Die App kombiniert:

- **Habit Tracker**: Definiere wiederkehrende Aufgaben (Habits)
- **Kanban Board**: Visualisiere deinen täglichen Workflow
- **Streak System**: Bleib motiviert durch Fortschrittstracking
- **WIP Limit**: Verhindert Überforderung durch max. 2 Tasks gleichzeitig in Bearbeitung

## Features

### ✅ Habit Management
- Erstelle Habits mit Name und Emoji (max. 20 Habits)
- **18 vordefinierte Emojis** für Aufräum-Tasks + Custom Emoji Picker
- **Active/Inactive Toggle** - Aktiviere nur die Habits die du aktuell tracken willst
- **Per-Habit Notifications** - Stelle für jedes Habit eine eigene Reminder-Zeit ein
- Verwalte deine wiederkehrenden Aufgaben
- Sieh deine aktuellen und längsten Streaks
- **Warning bei 10+ aktiven Habits** - Verhindert Überforderung

### 📋 Kanban Board
- **TODO**: Alle heutigen Cards
- **DOING**: Aktuell in Bearbeitung (Max 2!)
- **DONE**: Erledigte Tasks

### 🔥 Streak Tracking
- Streaks zählen nur wenn Card komplett durchläuft (TODO → DOING → DONE)
- Automatische Streak-Berechnung
- Best Streak Tracking

### 📱 Notifications
- **Morgens (8:00 Uhr)**: "Dein Board ist bereit!"
- **Abends (20:00 Uhr)**: "Zeit zum Abschließen!"

### 🎯 WIP Limit
- Maximal 2 Cards in "DOING" gleichzeitig
- Verhindert Multitasking und Chaos
- Visueller WIP-Indikator

### ⏱️ DOING Timer
- **Preset Timer** (15, 30, 60, 90 Min) wenn Card in DOING verschoben wird
- Notification wenn Zeit abläuft
- Verhindert dass Tasks vergessen werden
- Sichtbare Timer-Anzeige auf der Card

## Wie es funktioniert

1. **Habits erstellen**: Gehe zu "Habits" Tab und erstelle deine wiederkehrenden Tasks (max. 20)
2. **Habits aktivieren**: Tippe auf den Kreis links um Habits zu aktivieren/deaktivieren
3. **Fokus setzen**: Behalte nur 5-10 aktive Habits für bessere Ergebnisse
4. **Täglich starten**: Drücke "New Day" im Board → Generiert Cards aus **aktiven** Habits
5. **Arbeiten**: Ziehe Cards von TODO → DOING → DONE
6. **Streaks aufbauen**: Schließe Cards ab um deine Streaks zu halten

## Tech Stack

- **SwiftUI**: Modernes UI Framework
- **SwiftData**: Lokale Persistenz (iOS 17+)
- **UserNotifications**: Daily Reminders
- **Drag & Drop**: Native SwiftUI Gestures

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Öffne `Tidystreak.xcodeproj` in Xcode
2. Wähle ein Simulator oder Gerät
3. Build & Run (⌘R)

## Architektur

```
Tidystreak/
├── Models/
│   ├── Habit.swift          # Habit Data Model
│   └── Card.swift           # Daily Card Model
├── Views/
│   ├── ContentView.swift    # Tab Navigation
│   ├── BoardView.swift      # Kanban Board
│   ├── HabitsView.swift     # Habit Management
│   ├── AddHabitView.swift   # Create Habits
│   └── SettingsView.swift   # App Settings
├── Managers/
│   └── NotificationManager.swift  # Notification Logic
└── TidystreakApp.swift      # App Entry Point
```

## Geplante Features (Post-MVP)

- [ ] Statistiken & Charts
- [ ] Kalender-View für History
- [ ] Custom Habit Frequencies (wöchentlich, etc.)
- [ ] Export/Import von Habits
- [ ] iCloud Sync
- [ ] Widgets
- [ ] Dark Mode Anpassungen

## Lizenz

MIT License - Free to use and modify

---

**Viel Erfolg beim Aufräumen deines Chaos! 🧹✨**
