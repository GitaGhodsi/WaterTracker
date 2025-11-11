import SwiftUI
import UserNotifications

struct ContentView: View {
    // Stored data
    @AppStorage("dailyGoal") private var dailyGoal: Int = 8
    @AppStorage("todayCount") private var todayCount: Int = 0
    @AppStorage("lastOpenedDate") private var lastOpenedDate: String = ""

    // Notification settings (persist so it stays after app closes)
    @AppStorage("remindEnabled") private var remindEnabled: Bool = false
    @AppStorage("remindHour") private var remindHour: Int = 9
    @AppStorage("remindMinute") private var remindMinute: Int = 0

    // Local state for DatePicker UI
    @State private var remindTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
    @State private var showGoalSheet = false

    var body: some View {
        VStack(spacing: 32) {
            Text("Water Tracker")
                .font(.largeTitle.bold())

            // Progress
            VStack(spacing: 12) {
                Text("\(todayCount) / \(dailyGoal)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))

                ProgressView(value: Double(todayCount), total: Double(dailyGoal))
                    .padding(.horizontal, 40)
            }

            // + / - buttons
            HStack(spacing: 24) {
                Button(action: decrement) {
                    Text("−1")
                        .font(.largeTitle.bold())
                        .frame(width: 80, height: 80)
                }
                .buttonStyle(.borderedProminent)
                .tint(.gray)

                Button(action: increment) {
                    Text("+1")
                        .font(.largeTitle.bold())
                        .frame(width: 80, height: 80)
                }
                .buttonStyle(.borderedProminent)
            }

            Button("Set Daily Goal") { showGoalSheet = true }

            // ==== Notifications UI ====
            Toggle("Remind me daily", isOn: $remindEnabled)
                .onChange(of: remindEnabled) { _ in
                    handleNotificationSettingChange()
                }

            if remindEnabled {
                DatePicker("Time",
                           selection: $remindTime,
                           displayedComponents: .hourAndMinute)
                    .onChange(of: remindTime) { _ in
                        handleNotificationSettingChange()
                    }
                    .labelsHidden()
            }
            // ===========================

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showGoalSheet) {
            GoalSheet(dailyGoal: $dailyGoal)
        }
        .onAppear {
            resetIfNewDay()
            // Keep DatePicker in sync with saved hour/minute
            remindTime = Calendar.current.date(
                bySettingHour: remindHour,
                minute: remindMinute,
                second: 0,
                of: Date()
            ) ?? Date()

            // If reminders were ON, ensure they are scheduled
            if remindEnabled { scheduleDailyNotification(for: remindTime) }
        }
    }

    // MARK: - Counter logic
    private func increment() {
        guard todayCount < dailyGoal else { return }
        todayCount += 1
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func decrement() {
        guard todayCount > 0 else { return }
        todayCount -= 1
    }

    private func resetIfNewDay() {
        let today = formattedDate(Date())
        if lastOpenedDate != today {
            todayCount = 0
            lastOpenedDate = today
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    // MARK: - Notifications
    private func handleNotificationSettingChange() {
        if remindEnabled {
            // Save chosen hour/minute
            let comps = Calendar.current.dateComponents([.hour, .minute], from: remindTime)
            remindHour = comps.hour ?? 9
            remindMinute = comps.minute ?? 0

            scheduleDailyNotification(for: remindTime)
        } else {
            NotificationManager.cancelAll()
        }
    }

    private func scheduleDailyNotification(for time: Date) {
        NotificationManager.requestPermissionIfNeeded { granted in
            guard granted else {
                // Permission denied: turn toggle off to reflect reality
                DispatchQueue.main.async { self.remindEnabled = false }
                return
            }
            let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
            NotificationManager.scheduleDaily(hour: comps.hour ?? 9, minute: comps.minute ?? 0)
        }
    }
}

// MARK: - Simple Notifications Helper
enum NotificationManager {
    private static let identifier = "water.daily.reminder"

    static func requestPermissionIfNeeded(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                completion(true)
            case .denied:
                completion(false)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    completion(granted)
                }
            @unknown default:
                completion(false)
            }
        }
    }

    static func scheduleDaily(hour: Int, minute: Int) {
        cancelAll()

        let content = UNMutableNotificationContent()
        content.title = "Time to drink water 💧"
        content.body = "Log a glass now."
        content.sound = .default

        var date = DateComponents()
        date.hour = hour
        date.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
