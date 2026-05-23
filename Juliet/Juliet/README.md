# Juliet – iOS Expense Tracker

Personal expense tracker for direct iPhone deployment via Xcode. No App Store required.

---

## Stack

- **SwiftUI** – all UI
- **SwiftData** – local persistence (no backend)
- **Swift Charts** – analytics charts
- **UserNotifications** – daily expense reminders

---

## File structure

```
Juliet/
├── JulietApp.swift                         ← App entry point + SwiftData container
├── Extensions/
│   └── Color+Hex.swift                     ← Color(hex:) initializer
├── Managers/
│   └── NotificationManager.swift           ← Schedules daily push reminders
├── Models/
│   ├── Expense.swift
│   ├── RecurringPayment.swift
│   ├── SavingsEntry.swift
│   ├── CustomTag.swift
│   └── NotificationTime.swift
└── Views/
    ├── ContentView.swift                   ← 4-tab navigation
    ├── Analytics/
    │   └── AnalyticsView.swift
    ├── DailyLog/
    │   ├── AddEditExpenseView.swift
    │   ├── DailyLogView.swift
    │   ├── DailySummaryCard.swift
    │   └── ExpenseRowView.swift
    ├── Recurring/
    │   ├── AddRecurringView.swift
    │   └── RecurringView.swift
    ├── Savings/
    │   ├── AddSavingsEntryView.swift
    │   └── SavingsView.swift
    └── Settings/
        └── NotificationSettingsView.swift
```

---

## Xcode setup (step-by-step)

### 1 — Create the Xcode project

1. Open Xcode → **File › New › Project**
2. Choose **iOS › App** → click **Next**
3. Fill in:
   | Field | Value |
   |---|---|
   | Product Name | `Juliet` |
   | Team | your Apple ID / dev team |
   | Organization Identifier | e.g. `com.yourname` |
   | Bundle Identifier | e.g. `com.yourname.Juliet` |
   | Interface | SwiftUI |
   | Language | Swift |
   | Storage | **None** (SwiftData is added manually) |
4. **Uncheck** "Include Tests" (optional).
5. Choose a save location and click **Create**.

### 2 — Delete the generated boilerplate

Delete the auto-generated `ContentView.swift` and `<AppName>App.swift` files — you'll use the ones from this folder instead.

### 3 — Add the source files

Drag the entire contents of this `Juliet/` folder into the Xcode project navigator **onto the yellow folder** (your app target):

- Make sure **"Copy items if needed"** is checked.
- Set **"Added folders"** to **"Create groups"**.
- All 5 targets checkboxes should have your app target selected.

Xcode will create matching groups for `Models/`, `Views/`, `Managers/`, etc.

### 4 — Enable required capabilities

In the project navigator, click the blue **Juliet** project icon → select your app **Target** → **Signing & Capabilities** tab:

- Click **+ Capability** and add **Push Notifications** (needed for local notifications on device).
- Your **Team** must be set to a valid Apple ID (free tier works fine for personal use).

### 5 — Set deployment target

Still in the Target settings → **General** tab → set **Minimum Deployments** to **iOS 17.0** (SwiftData requires iOS 17+).

### 6 — Trust your developer certificate on iPhone

1. On your iPhone: **Settings › General › VPN & Device Management** → tap your Apple ID → **Trust**.
2. In Xcode, select your iPhone from the device picker at the top.
3. Press **⌘R** (Run).

Xcode will build, sign, and install Juliet directly on your device.

---

## Features

| Tab | What it does |
|---|---|
| **Log** | Add/edit/delete daily expenses. Swipe left to delete, right to edit. Date selector lets you navigate days. Daily summary card at top. |
| **Analytics** | Pie + bar charts by tag or account. Line chart for daily trend. Week / Month / Custom date range. |
| **Recurring** | Track Netflix, SIP, mutual funds, rent, etc. One tap to mark paid. Shows due vs. paid status. |
| **Savings** | Log monthly salary + set-aside amount. Shows SBI balance, savings rate gauge, and history chart. |
| **Bell icon** | Notification settings — 3–6 customizable daily reminder times. |

---

## Notes

- All data is stored **locally** on device via SwiftData — no cloud, no account required.
- Recurring payments use a "mark paid" model per period (weekly / monthly / yearly).
- Default notification times seed automatically on first launch: 9:00 AM, 1:30 PM, 9:00 PM.
- Custom tags you create are persisted alongside the predefined ones.
