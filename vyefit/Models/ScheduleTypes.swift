//
//  ScheduleTypes.swift
//  vyefit
//
//  Schedule models for weekly workout/run planning.
//

import Foundation
import SwiftUI

// MARK: - Schedule Item Types

enum ScheduleItemType: String, CaseIterable, Codable, Identifiable {
    case workout = "Workout"
    case run = "Run"
    case rest = "Rest"
    case busy = "Busy"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .workout:
            return "dumbbell.fill"
        case .run:
            return "figure.run"
        case .rest:
            return "bed.double.fill"
        case .busy:
            return "briefcase.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .workout:
            return Theme.terracotta
        case .run:
            return Theme.sage
        case .rest:
            return Theme.restDay
        case .busy:
            return Theme.busyDay
        }
    }
}

// MARK: - Run Types for Schedule

enum ScheduleRunType: String, CaseIterable, Codable, Identifiable {
    case easy = "Easy Run"
    case tempo = "Tempo Run"
    case interval = "Intervals"
    case long = "Long Run"
    case recovery = "Recovery Run"
    case hill = "Hill Repeats"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .easy:
            return "figure.run"
        case .tempo:
            return "speedometer"
        case .interval:
            return "timer"
        case .long:
            return "map"
        case .recovery:
            return "heart.fill"
        case .hill:
            return "arrow.up.right"
        }
    }
    
    var description: String {
        switch self {
        case .easy:
            return "Comfortable pace, conversational"
        case .tempo:
            return "Comfortably hard, sustainable pace"
        case .interval:
            return "Alternating fast/slow segments"
        case .long:
            return "Extended distance run"
        case .recovery:
            return "Very easy pace, active rest"
        case .hill:
            return "Uphill repeats with recovery"
        }
    }
}

// MARK: - Schedule Item

struct ScheduleItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var type: ScheduleItemType
    var workoutId: UUID? // For workout type
    var runType: ScheduleRunType? // For run type
    var notes: String?
    var duration: Int? // Estimated duration in minutes
    
    static func workout(_ workoutId: UUID, duration: Int? = nil, notes: String? = nil) -> ScheduleItem {
        ScheduleItem(type: .workout, workoutId: workoutId, runType: nil, notes: notes, duration: duration)
    }
    
    static func run(_ runType: ScheduleRunType, duration: Int? = nil, notes: String? = nil) -> ScheduleItem {
        ScheduleItem(type: .run, workoutId: nil, runType: runType, notes: notes, duration: duration)
    }
    
    static func rest(notes: String? = nil) -> ScheduleItem {
        ScheduleItem(type: .rest, workoutId: nil, runType: nil, notes: notes, duration: nil)
    }
    
    static func busy(notes: String? = nil) -> ScheduleItem {
        ScheduleItem(type: .busy, workoutId: nil, runType: nil, notes: notes, duration: nil)
    }
}

// MARK: - Schedule Day

enum DayOfWeek: String, CaseIterable, Codable, Identifiable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"
    
    var id: String { rawValue }
    
    var shortName: String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
    
    var index: Int {
        switch self {
        case .monday: return 0
        case .tuesday: return 1
        case .wednesday: return 2
        case .thursday: return 3
        case .friday: return 4
        case .saturday: return 5
        case .sunday: return 6
        }
    }
    
    static func from(date: Date) -> DayOfWeek {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        // Convert to Monday-first: Monday=0, Sunday=6
        let index = (weekday + 5) % 7
        return DayOfWeek.allCases[index]
    }
}

struct ScheduleDay: Identifiable, Codable, Equatable {
    var id = UUID()
    var day: DayOfWeek
    var items: [ScheduleItem]
    
    var isEmpty: Bool {
        items.isEmpty
    }
}

// MARK: - Schedule Mode

enum ScheduleRepeatMode: String, CaseIterable, Codable, Identifiable {
    case weekly = "Weekly"
    case newEachWeek = "New Each Week"
    case cyclic = "Cyclic"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .weekly:
            return "Repeat the same schedule every week"
        case .newEachWeek:
            return "Create a fresh schedule each week"
        case .cyclic:
            return "Cycle through multiple schedules"
        }
    }
    
    var icon: String {
        switch self {
        case .weekly:
            return "arrow.circlepath"
        case .newEachWeek:
            return "calendar.badge.plus"
        case .cyclic:
            return "arrow.3.trianglepath"
        }
    }
}

// MARK: - Schedule

struct Schedule: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var description: String?
    var color: String // Hex color
    var days: [ScheduleDay]
    var createdAt: Date
    var updatedAt: Date
    var isActive: Bool
    var order: Int // For cyclic mode ordering
    
    var totalItems: Int {
        days.reduce(0) { $0 + $1.items.count }
    }
    
    var workoutDays: Int {
        days.filter { day in
            day.items.contains { $0.type == .workout }
        }.count
    }
    
    var runDays: Int {
        days.filter { day in
            day.items.contains { $0.type == .run }
        }.count
    }
    
    var restDays: Int {
        days.filter { day in
            day.items.contains { $0.type == .rest }
        }.count
    }
    
    static func createEmpty(name: String, color: String = "CC7359") -> Schedule {
        let days = DayOfWeek.allCases.map { day in
            ScheduleDay(day: day, items: [])
        }
        return Schedule(
            name: name,
            description: nil,
            color: color,
            days: days,
            createdAt: Date(),
            updatedAt: Date(),
            isActive: false,
            order: 0
        )
    }
}

// MARK: - Schedule Settings

struct ScheduleSettings: Codable {
    var repeatMode: ScheduleRepeatMode
    var schedules: [Schedule]
    var currentScheduleIndex: Int // For cyclic mode
    var weekStartDay: DayOfWeek
    var notificationsEnabled: Bool
    
    var activeSchedules: [Schedule] {
        schedules.filter { $0.isActive }.sorted { $0.order < $1.order }
    }
    
    var currentSchedule: Schedule? {
        switch repeatMode {
        case .weekly, .newEachWeek:
            return schedules.first { $0.isActive }
        case .cyclic:
            let active = activeSchedules
            guard !active.isEmpty else { return nil }
            let index = currentScheduleIndex % active.count
            return active[index]
        }
    }
    
    static let `default` = ScheduleSettings(
        repeatMode: .weekly,
        schedules: [],
        currentScheduleIndex: 0,
        weekStartDay: .monday,
        notificationsEnabled: true
    )
}

// MARK: - Schedule Presets

enum SchedulePreset {
    case pushPullLegs
    case upperLower
    case fullBody
    case runFocus
    case hybrid
    
    var name: String {
        switch self {
        case .pushPullLegs:
            return "Push Pull Legs"
        case .upperLower:
            return "Upper/Lower Split"
        case .fullBody:
            return "Full Body"
        case .runFocus:
            return "Run Focus"
        case .hybrid:
            return "Hybrid Training"
        }
    }
    
    func generate(workouts: [UserWorkout]) -> Schedule? {
        switch self {
        case .pushPullLegs:
            return generatePPL(workouts: workouts)
        case .upperLower:
            return generateUpperLower(workouts: workouts)
        case .fullBody:
            return generateFullBody(workouts: workouts)
        case .runFocus:
            return generateRunFocus()
        case .hybrid:
            return generateHybrid()
        }
    }
    
    private func generatePPL(workouts: [UserWorkout]) -> Schedule? {
        var schedule = Schedule.createEmpty(name: name, color: "CC7359")
        
        // Try to find push, pull, leg workouts
        let pushWorkout = workouts.first { $0.name.lowercased().contains("push") }
        let pullWorkout = workouts.first { $0.name.lowercased().contains("pull") }
        let legWorkout = workouts.first { $0.name.lowercased().contains("leg") }
        
        if let push = pushWorkout {
            schedule.days[0].items = [.workout(push.id, duration: 60)]
        }
        if let pull = pullWorkout {
            schedule.days[2].items = [.workout(pull.id, duration: 60)]
        }
        if let legs = legWorkout {
            schedule.days[4].items = [.workout(legs.id, duration: 60)]
        }
        
        schedule.days[1].items = [.rest()]
        schedule.days[3].items = [.rest()]
        schedule.days[5].items = [.rest()]
        schedule.days[6].items = [.rest()]
        
        return schedule
    }
    
    private func generateUpperLower(workouts: [UserWorkout]) -> Schedule? {
        var schedule = Schedule.createEmpty(name: name, color: "8CA680")
        
        let upperWorkout = workouts.first { $0.name.lowercased().contains("upper") || $0.name.lowercased().contains("push") }
        let lowerWorkout = workouts.first { $0.name.lowercased().contains("lower") || $0.name.lowercased().contains("leg") }
        
        if let upper = upperWorkout {
            schedule.days[0].items = [.workout(upper.id, duration: 60)]
            schedule.days[3].items = [.workout(upper.id, duration: 60)]
        }
        if let lower = lowerWorkout {
            schedule.days[1].items = [.workout(lower.id, duration: 60)]
            schedule.days[4].items = [.workout(lower.id, duration: 60)]
        }
        
        schedule.days[2].items = [.rest()]
        schedule.days[5].items = [.rest()]
        schedule.days[6].items = [.rest()]
        
        return schedule
    }
    
    private func generateFullBody(workouts: [UserWorkout]) -> Schedule? {
        var schedule = Schedule.createEmpty(name: name, color: "A3C4BC")
        
        let fullBodyWorkout = workouts.first { $0.name.lowercased().contains("full") }
        
        if let fb = fullBodyWorkout {
            schedule.days[0].items = [.workout(fb.id, duration: 60)]
            schedule.days[2].items = [.workout(fb.id, duration: 60)]
            schedule.days[4].items = [.workout(fb.id, duration: 60)]
        }
        
        schedule.days[1].items = [.rest()]
        schedule.days[3].items = [.rest()]
        schedule.days[5].items = [.rest()]
        schedule.days[6].items = [.rest()]
        
        return schedule
    }
    
    private func generateRunFocus() -> Schedule {
        var schedule = Schedule.createEmpty(name: name, color: "6B8E7B")
        
        schedule.days[0].items = [.run(.easy, duration: 30)]
        schedule.days[1].items = [.rest()]
        schedule.days[2].items = [.run(.tempo, duration: 40)]
        schedule.days[3].items = [.rest()]
        schedule.days[4].items = [.run(.interval, duration: 45)]
        schedule.days[5].items = [.run(.long, duration: 60)]
        schedule.days[6].items = [.rest()]
        
        return schedule
    }
    
    private func generateHybrid() -> Schedule {
        var schedule = Schedule.createEmpty(name: name, color: "D4A574")
        
        schedule.days[0].items = [.run(.easy, duration: 30)]
        schedule.days[2].items = [.run(.tempo, duration: 35)]
        schedule.days[4].items = [.run(.interval, duration: 40)]
        schedule.days[6].items = [.run(.long, duration: 50)]
        
        schedule.days[1].items = [.rest()]
        schedule.days[3].items = [.rest()]
        schedule.days[5].items = [.rest()]
        
        return schedule
    }
}
