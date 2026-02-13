//
//  RemindersView.swift
//  vyefit
//
//  Detail screen for reminder preferences with actual notification scheduling.
//

import SwiftUI
import UserNotifications

struct RemindersView: View {
    private enum HydrationInterval: Int, CaseIterable, Identifiable {
        case one = 1
        case two = 2
        case three = 3
        case four = 4

        var id: Int { rawValue }

        var label: String {
            "\(rawValue)h"
        }
    }

    @AppStorage("workoutReminders") private var workoutReminders = false
    @AppStorage("hydrationReminders") private var hydrationReminders = false
    @AppStorage("mindfulnessReminders") private var mindfulnessReminders = false
    @AppStorage("hydrationIntervalHours") private var hydrationIntervalHours = HydrationInterval.two.rawValue
    
    @AppStorage("workoutReminderHour") private var workoutReminderHour = 8
    @AppStorage("workoutReminderMinute") private var workoutReminderMinute = 0
    @AppStorage("hydrationReminderHour") private var hydrationReminderHour = 9
    @AppStorage("hydrationReminderMinute") private var hydrationReminderMinute = 0
    @AppStorage("mindfulnessReminderHour") private var mindfulnessReminderHour = 20
    @AppStorage("mindfulnessReminderMinute") private var mindfulnessReminderMinute = 0

    @State private var showPermissionAlert = false
    @State private var permissionDenied = false
    
    @State private var workoutTime: Date
    @State private var hydrationTime: Date
    @State private var mindfulnessTime: Date
    
    init() {
        let calendar = Calendar.current
        
        let workoutHour = UserDefaults.standard.integer(forKey: "workoutReminderHour")
        let workoutMinute = UserDefaults.standard.integer(forKey: "workoutReminderMinute")
        _workoutTime = State(initialValue: calendar.date(bySettingHour: workoutHour, minute: workoutMinute, second: 0, of: Date()) ?? Date())
        
        let hydrationHour = UserDefaults.standard.integer(forKey: "hydrationReminderHour")
        let hydrationMinute = UserDefaults.standard.integer(forKey: "hydrationReminderMinute")
        _hydrationTime = State(initialValue: calendar.date(bySettingHour: hydrationHour, minute: hydrationMinute, second: 0, of: Date()) ?? Date())
        
        let mindfulnessHour = UserDefaults.standard.integer(forKey: "mindfulnessReminderHour")
        let mindfulnessMinute = UserDefaults.standard.integer(forKey: "mindfulnessReminderMinute")
        _mindfulnessTime = State(initialValue: calendar.date(bySettingHour: mindfulnessHour, minute: mindfulnessMinute, second: 0, of: Date()) ?? Date())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SettingsCard("Workout") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Workout reminders", isOn: $workoutReminders)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.terracotta)
                            .onChange(of: workoutReminders) { _, newValue in
                                if newValue { requestPermissionAndSchedule(type: .workout) }
                                else { cancelNotifications(for: .workout) }
                            }

                        DatePicker("Preferred time", selection: $workoutTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .tint(Theme.terracotta)
                            .opacity(workoutReminders ? 1 : 0.45)
                            .disabled(!workoutReminders)
                            .onChange(of: workoutTime) { _, newTime in
                                saveAndSchedule(newTime, type: .workout)
                            }
                    }
                }

                SettingsCard("Hydration") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Hydration check-ins", isOn: $hydrationReminders)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.sage)
                            .onChange(of: hydrationReminders) { _, newValue in
                                if newValue { requestPermissionAndSchedule(type: .hydration) }
                                else { cancelNotifications(for: .hydration) }
                            }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Check-in interval")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)

                            Picker("Check-in interval", selection: $hydrationIntervalHours) {
                                ForEach(HydrationInterval.allCases) { interval in
                                    Text(interval.label)
                                        .tag(interval.rawValue)
                                }
                            }
                            .pickerStyle(.segmented)
                            .tint(Theme.sage)
                            .onChange(of: hydrationIntervalHours) { _, _ in
                                if hydrationReminders { scheduleHydrationNotifications() }
                            }
                        }
                        .opacity(hydrationReminders ? 1 : 0.45)
                        .disabled(!hydrationReminders)

                        DatePicker("First reminder", selection: $hydrationTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .tint(Theme.sage)
                            .opacity(hydrationReminders ? 1 : 0.45)
                            .disabled(!hydrationReminders)
                            .onChange(of: hydrationTime) { _, newTime in
                                saveAndSchedule(newTime, type: .hydration)
                            }
                    }
                }

                SettingsCard("Mindfulness") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Mindful minutes prompt", isOn: $mindfulnessReminders)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.textPrimary)
                            .tint(Theme.stone)
                            .onChange(of: mindfulnessReminders) { _, newValue in
                                if newValue { requestPermissionAndSchedule(type: .mindfulness) }
                                else { cancelNotifications(for: .mindfulness) }
                            }

                        Text("Prompts you to log short mindfulness breaks.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)

                        DatePicker("Preferred time", selection: $mindfulnessTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .tint(Theme.stone)
                            .opacity(mindfulnessReminders ? 1 : 0.45)
                            .disabled(!mindfulnessReminders)
                            .onChange(of: mindfulnessTime) { _, newTime in
                                saveAndSchedule(newTime, type: .mindfulness)
                            }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Theme.background)
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.large)
        .alert("Enable Notifications", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { 
                workoutReminders = false
                hydrationReminders = false
                mindfulnessReminders = false
            }
        } message: {
            Text("Please allow notifications in Settings to receive reminders.")
        }
        .onAppear {
            checkNotificationStatus()
            syncTimesFromStorage()
        }
    }
    
    private enum ReminderType {
        case workout
        case hydration
        case mindfulness
    }
    
    private func syncTimesFromStorage() {
        let calendar = Calendar.current
        workoutTime = calendar.date(bySettingHour: workoutReminderHour, minute: workoutReminderMinute, second: 0, of: Date()) ?? Date()
        hydrationTime = calendar.date(bySettingHour: hydrationReminderHour, minute: hydrationReminderMinute, second: 0, of: Date()) ?? Date()
        mindfulnessTime = calendar.date(bySettingHour: mindfulnessReminderHour, minute: mindfulnessReminderMinute, second: 0, of: Date()) ?? Date()
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                permissionDenied = settings.authorizationStatus == .denied
            }
        }
    }
    
    private func requestPermissionAndSchedule(type: ReminderType) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    switch type {
                    case .workout:
                        scheduleNotification(for: .workout)
                    case .hydration:
                        scheduleHydrationNotifications()
                    case .mindfulness:
                        scheduleNotification(for: .mindfulness)
                    }
                } else {
                    showPermissionAlert = true
                }
            }
        }
    }
    
    private func saveAndSchedule(_ date: Date, type: ReminderType) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        
        switch type {
        case .workout:
            workoutReminderHour = components.hour ?? 8
            workoutReminderMinute = components.minute ?? 0
            if workoutReminders { scheduleNotification(for: .workout) }
        case .hydration:
            hydrationReminderHour = components.hour ?? 9
            hydrationReminderMinute = components.minute ?? 0
            if hydrationReminders { scheduleHydrationNotifications() }
        case .mindfulness:
            mindfulnessReminderHour = components.hour ?? 20
            mindfulnessReminderMinute = components.minute ?? 0
            if mindfulnessReminders { scheduleNotification(for: .mindfulness) }
        }
    }
    
    private func scheduleNotification(for type: ReminderType) {
        let center = UNUserNotificationCenter.current()
        
        let (id, title, body, hour, minute): (String, String, String, Int, Int) = {
            switch type {
            case .workout:
                return ("workout-reminder", "Workout Time!", "Time to get moving! Your workout is waiting.", workoutReminderHour, workoutReminderMinute)
            case .mindfulness:
                return ("mindfulness-reminder", "Mindful Moment", "Take a few minutes for yourself. Log your mindfulness break.", mindfulnessReminderHour, mindfulnessReminderMinute)
            case .hydration:
                return ("hydration-reminder", "Stay Hydrated", "Time to drink some water!", hydrationReminderHour, hydrationReminderMinute)
            }
        }()
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }
    
    private func scheduleHydrationNotifications() {
        let center = UNUserNotificationCenter.current()
        
        let ids = (0..<24).map { "hydration-reminder-\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        
        let content = UNMutableNotificationContent()
        content.title = "Stay Hydrated"
        content.body = "Time to drink some water!"
        content.sound = .default
        
        let interval = hydrationIntervalHours
        var hour = hydrationReminderHour
        let minute = hydrationReminderMinute
        
        for i in 0..<24 {
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "hydration-reminder-\(i)", content: content, trigger: trigger)
            center.add(request)
            
            hour = (hour + interval) % 24
        }
    }
    
    private func cancelNotifications(for type: ReminderType) {
        let center = UNUserNotificationCenter.current()
        
        switch type {
        case .workout:
            center.removePendingNotificationRequests(withIdentifiers: ["workout-reminder"])
        case .hydration:
            let ids = (0..<24).map { "hydration-reminder-\($0)" }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        case .mindfulness:
            center.removePendingNotificationRequests(withIdentifiers: ["mindfulness-reminder"])
        }
    }
}

#Preview {
    NavigationStack {
        RemindersView()
    }
}
