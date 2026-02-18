//
//  RunConfigSheet.swift
//  vyefit
//
//  Configuration sheet for setting up a run session.
//

import SwiftUI

struct RunConfigSheet: View {
    let type: RunGoalType
    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutStore.self) private var workoutStore
    
    // State
    private let store = RunTargetStore.shared
    @State private var selectedTarget: RunTarget?
    @State private var showNewTargetSheet = false
    @State private var selectedZone: HeartRateZone?
    @State private var showStartConfirmation = false
    @State private var showAppleWorkoutPrompt = false
    
    // Interval State
    @State private var intervalWorkout = IntervalWorkout.defaultInterval
    
    // Units
    @AppStorage("distanceUnit") private var distanceUnit = "Kilometers"
    
    var unitString: String {
        let dist = distanceUnit == "Kilometers" ? "km" : "mi"
        switch type {
        case .distance: return dist
        case .pace: return "min/\(dist)"
        case .intervals: return dist
        default: return ""
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                
                if type == .quickStart {
                    quickStartView
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            /*if type == .intervals {
                                IntervalBuilderView(workout: $intervalWorkout, unit: unitString)
                            } else*/ if type == .heartRate {
                                HeartRateZonePicker(selectedZone: $selectedZone)
                            } else {
                                targetSelectionView
                            }
                        }
                        .padding(20)
                    }
                }
                
                startButtonFooter
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .sheet(isPresented: $showNewTargetSheet) {
                NewTargetSheet(type: type, unit: unitString) { newTarget in
                    store.addTarget(newTarget)
                    selectedTarget = newTarget
                }
            }
        }
        .presentationDetents(type == .quickStart ? [.medium] : [.large])
    }
    
    private var quickStartView: some View {
//        VStack(spacing: 24) {
//            Image(systemName: "figure.run.circle.fill")
//                .font(.system(size: 64))
//                .foregroundStyle(Theme.terracotta)
					
					VStack(spacing: 8) {
                Text("Ready to run?")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                Text("Just hit start and go")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textSecondary)
            }
//        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var startButtonFooter: some View {
        VStack(spacing: 12) {
            Divider()
            
            if workoutStore.activeSession != nil {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                    Text("A workout is already in progress")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(Theme.terracotta)
                .padding(.horizontal, 20)
            }
            
            Button {
                showStartConfirmation = true
            } label: {
                Text(workoutStore.activeSession != nil ? "Session in Progress" : "Track on Apple Workout")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(workoutStore.activeSession != nil ? Theme.textSecondary.opacity(0.5) : Theme.terracotta)
                    .clipShape(Capsule())
            }
            .disabled(workoutStore.activeSession != nil)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Theme.background)
        .alert("Track Run in Apple Workout?", isPresented: $showStartConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("OK") {
                showAppleWorkoutPrompt = true
            }
        } message: {
            Text("Vyefit no longer runs live activity tracking. Start the run from Apple Workout on your watch or iPhone.")
        }
        .alert("How to Track", isPresented: $showAppleWorkoutPrompt) {
            Button("Done") { dismiss() }
        } message: {
            Text("Open the Workout app on Apple Watch or iPhone, start your run there, then return to Vyefit to review imported sessions.")
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 32))
                .foregroundStyle(Theme.terracotta)
                .padding(.top, 20)
            
            Text(type.rawValue)
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.textPrimary)
            
            Divider()
        }
        .background(Theme.background)
    }
    
    private var targetSelectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Select Target")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Button {
                    showNewTargetSheet = true
                } label: {
                    Label("New Target", systemImage: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.terracotta)
                }
            }
            
            // Default Targets - Horizontal Scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.defaultTargets(for: type)) { target in
                        TargetCard(target: target, isSelected: selectedTarget?.id == target.id, unit: unitString)
                            .onTapGesture {
                                withAnimation { selectedTarget = target }
                            }
                    }
                }
            }
            
            // Custom Targets - 2 Column Grid
            let customTargets = store.customTargets(for: type)
            if !customTargets.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Custom Targets")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(stride(from: 0, to: customTargets.count, by: 2)), id: \.self) { index in
                            HStack(spacing: 12) {
                                TargetCard(target: customTargets[index], isSelected: selectedTarget?.id == customTargets[index].id, unit: unitString)
                                    .onTapGesture {
                                        withAnimation { selectedTarget = customTargets[index] }
                                    }
                                
                                if index + 1 < customTargets.count {
                                    TargetCard(target: customTargets[index + 1], isSelected: selectedTarget?.id == customTargets[index + 1].id, unit: unitString)
                                        .onTapGesture {
                                            withAnimation { selectedTarget = customTargets[index + 1] }
                                        }
                                }
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
            
            if let selected = selectedTarget {
                VStack(spacing: 8) {
                    Text("Target Set")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.sage)
                        .textCase(.uppercase)
                    
                    Text(selected.description(unit: unitString))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// MARK: - Subviews

struct TargetCard: View {
    let target: RunTarget
    let isSelected: Bool
    let unit: String
    
    private var isMarathonTarget: Bool {
        target.type == .distance && (target.name == "Half Marathon" || target.name == "Marathon")
    }
    
    private var displayValue: String {
        guard isMarathonTarget else {
            return target.description(unit: unit)
        }
        
        // For marathon targets, show rounded values
        let isMiles = unit == "mi"
        if target.name == "Half Marathon" {
            return isMiles ? "13.1 mi" : "21 km"
        } else { // Marathon
            return isMiles ? "26.2 mi" : "42 km"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(target.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? Theme.cream : Theme.textPrimary)
                .lineLimit(1)

            if target.type != .pace { // Pace usually has name = value description
                Text(displayValue)
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? Theme.cream.opacity(0.8) : Theme.textSecondary)
            }
        }
        .padding(14)
        .frame(width: 120, height: 80, alignment: .topLeading)
        .background(isSelected ? Theme.terracotta : Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.terracotta.opacity(isSelected ? 0 : 0.2), lineWidth: 1)
        )
    }
}

struct HeartRateZonePicker: View {
    @Binding var selectedZone: HeartRateZone?
    let zones = HeartRateZone.defaults
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Zone")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            
            ForEach(zones) { zone in
                Button {
                    withAnimation { selectedZone = zone }
                } label: {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(zone.color)
                            .frame(width: 12, height: 12)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Zone \(zone.id) - \(zone.name)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            
                            Text("\(zone.minBPM) - \(zone.maxBPM) BPM")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        if selectedZone?.id == zone.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Theme.terracotta)
                        }
                    }
                    .padding(16)
                    .background(Theme.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedZone?.id == zone.id ? Theme.terracotta : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct IntervalBuilderView: View {
    @Binding var workout: IntervalWorkout
    let unit: String
    
    // Quick loop state
    @State private var loopRepeats: Int = 5
    @State private var loopWork = IntervalStep(type: .work, durationType: .time, value: 60)
    @State private var loopRest = IntervalStep(type: .rest, durationType: .time, value: 60)
    @State private var showQuickLoop = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Warmup
            ToggleSection(title: "Warmup", isOn: $workout.warmupEnabled) {
                WarmupCooldownRow(step: $workout.warmupStep, unit: unit)
            }
            
            // Steps Section
            VStack(spacing: 16) {
                HStack {
                    Text("Interval Steps")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("\(workout.steps.count) steps")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                if workout.steps.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.dashed")
                            .font(.system(size: 28))
                            .foregroundStyle(Theme.textSecondary.opacity(0.5))
                        Text("No steps yet")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(workout.steps.enumerated()), id: \.element.id) { index, step in
                            IntervalStepRow(
                                step: Binding(
                                    get: { workout.steps[index] },
                                    set: { workout.steps[index] = $0 }
                                ),
                                label: "\(step.type.rawValue) \(index + 1)",
                                color: step.type == .work ? Theme.terracotta : Theme.sage,
                                unit: unit,
                                onDelete: { workout.steps.remove(at: index) }
                            )
                        }
                    }
                    .padding(12)
                    .background(Theme.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                // Add Step Buttons
                HStack(spacing: 12) {
                    Button {
                        withAnimation {
                            workout.steps.append(IntervalStep(type: .work, durationType: .time, value: 60))
                        }
                    } label: {
                        Label("Add Work", systemImage: "plus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.cream)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Theme.terracotta)
                            .clipShape(Capsule())
                    }

                    Button {
                        withAnimation {
                            workout.steps.append(IntervalStep(type: .rest, durationType: .time, value: 60))
                        }
                    } label: {
                        Label("Add Rest", systemImage: "plus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.cream)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Theme.sage)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
                
                // Quick Loop
                VStack(spacing: 12) {
                    Button {
                        showQuickLoop.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.2.squarepath")
                            Text("Quick Loop")
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Image(systemName: showQuickLoop ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(Theme.terracotta)
                    }
                    
                    if showQuickLoop {
                        VStack(spacing: 12) {
                            Stepper("Repeats: \(loopRepeats)x", value: $loopRepeats, in: 1...30)
                                .font(.system(size: 14, weight: .medium))
                            
                            IntervalStepRow(step: $loopWork, label: "Work", color: Theme.terracotta, unit: unit, onDelete: nil)
                            IntervalStepRow(step: $loopRest, label: "Rest", color: Theme.sage, unit: unit, onDelete: nil)
                            
                            Button {
                                workout.steps = IntervalWorkout.generateLoop(
                                    workStep: loopWork,
                                    restStep: loopRest,
                                    repeats: loopRepeats
                                )
                                showQuickLoop = false
                            } label: {
                                Text("Generate \(loopRepeats * 2) Steps")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.cream)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Theme.terracotta)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(12)
                        .background(Theme.cream)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            
            // Cooldown
            ToggleSection(title: "Cooldown", isOn: $workout.cooldownEnabled) {
                WarmupCooldownRow(step: $workout.cooldownStep, unit: unit)
            }
            
            // Summary
            if !workout.steps.isEmpty {
                VStack(spacing: 6) {
                    Text("WORKOUT SUMMARY")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .tracking(1)
                    
                    let workCount = workout.steps.filter { $0.type == .work }.count
                    let restCount = workout.steps.filter { $0.type == .rest }.count
                    
                    Text("\(workCount) work · \(restCount) rest intervals")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    
                    if let est = estimatedDuration {
                        Text("≈ \(est)")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var estimatedDuration: String? {
        var totalSec: Double = 0
        if workout.warmupEnabled && workout.warmupStep.durationType == .time { 
            totalSec += workout.warmupStep.value 
        }
        if workout.cooldownEnabled && workout.cooldownStep.durationType == .time { 
            totalSec += workout.cooldownStep.value 
        }
        for step in workout.steps {
            if step.durationType == .time {
                totalSec += step.value
            }
        }
        guard totalSec > 0 else { return nil }
        let m = Int(totalSec) / 60
        let s = Int(totalSec) % 60
        if m >= 60 {
            return String(format: "%dh %dm", m / 60, m % 60)
        }
        return String(format: "%d:%02d", m, s)
    }
}

struct WarmupCooldownRow: View {
    @Binding var step: IntervalStep
    let unit: String
    @State private var showValuePicker = false
    
    var body: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(IntervalDurationType.allCases, id: \.self) { type in
                    Button {
                        step.durationType = type
                    } label: {
                        Label(type.rawValue, systemImage: iconForType(type))
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: iconForType(step.durationType))
                        .font(.system(size: 11))
                    Text(step.durationType.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(Theme.terracotta)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(minWidth: 95)
                .background(Theme.terracotta.opacity(0.1))
                .clipShape(Capsule())
            }
            
            Spacer()
            
            Button {
                showValuePicker = true
            } label: {
                Text(formatValue(step))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: step.durationType)
        .sheet(isPresented: $showValuePicker) {
            IntervalValuePicker(step: $step, unit: unit)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func iconForType(_ type: IntervalDurationType) -> String {
        switch type {
        case .time: return "clock"
        case .distance: return "location.fill"
        case .calories: return "flame"
        }
    }
    
    func formatValue(_ step: IntervalStep) -> String {
        switch step.durationType {
        case .time:
            let totalSec = Int(step.value)
            let h = totalSec / 3600
            let m = (totalSec % 3600) / 60
            let s = totalSec % 60
            if h > 0 {
                return String(format: "%d:%02d:%02d", h, m, s)
            }
            return String(format: "%d:%02d", m, s)
        case .distance:
            let km = Int(step.value)
            let m = Int((step.value - Double(km)) * 1000)
            if km > 0 {
                return String(format: "%d.%03d %@", km, m, unit)
            }
            return String(format: "%dm", m)
        case .calories:
            return "\(Int(step.value)) kcal"
        }
    }
}

struct IntervalStepRow: View {
    @Binding var step: IntervalStep
    let label: String
    let color: Color
    let unit: String
    var onDelete: (() -> Void)?
    @State private var showValuePicker = false
    
    var body: some View {
        HStack(spacing: 8) {
            Capsule()
                .fill(color)
                .frame(width: 4, height: 28)
            
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 60, alignment: .leading)
            
            Menu {
                ForEach(IntervalDurationType.allCases, id: \.self) { type in
                    Button {
                        step.durationType = type
                    } label: {
                        Label(type.rawValue, systemImage: iconForType(type))
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: iconForType(step.durationType))
                        .font(.system(size: 11))
                    Text(step.durationType.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(Theme.terracotta)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(minWidth: 95)
                .background(Theme.terracotta.opacity(0.1))
                .clipShape(Capsule())
            }
            
            Spacer()
            
            Button {
                showValuePicker = true
            } label: {
                Text(formatValue(step))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            if let onDelete {
                Button {
                    withAnimation { onDelete() }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textSecondary.opacity(0.5))
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: step.durationType)
        .sheet(isPresented: $showValuePicker) {
            IntervalValuePicker(step: $step, unit: unit)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func iconForType(_ type: IntervalDurationType) -> String {
        switch type {
        case .time: return "clock"
        case .distance: return "location.fill"
        case .calories: return "flame"
        }
    }
    
    func formatValue(_ step: IntervalStep) -> String {
        switch step.durationType {
        case .time:
            let totalSec = Int(step.value)
            let h = totalSec / 3600
            let m = (totalSec % 3600) / 60
            let s = totalSec % 60
            if h > 0 {
                return String(format: "%d:%02d:%02d", h, m, s)
            }
            return String(format: "%d:%02d", m, s)
        case .distance:
            let km = Int(step.value)
            let m = Int((step.value - Double(km)) * 1000)
            if km > 0 {
                return String(format: "%d.%03d %@", km, m, unit)
            }
            return String(format: "%dm", m)
        case .calories:
            return "\(Int(step.value)) kcal"
        }
    }
}

struct IntervalValuePicker: View {
    @Binding var step: IntervalStep
    let unit: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var hours: Int = 0
    @State private var minutes: Int = 1
    @State private var seconds: Int = 0
    
    @State private var kilometers: Int = 0
    @State private var meters: Int = 0
    
    @State private var calories: Int = 100
    
    init(step: Binding<IntervalStep>, unit: String) {
        self._step = step
        self.unit = unit
        
        let val = step.wrappedValue.value
        switch step.wrappedValue.durationType {
        case .time:
            _hours = State(initialValue: Int(val) / 3600)
            _minutes = State(initialValue: (Int(val) % 3600) / 60)
            _seconds = State(initialValue: Int(val) % 60)
        case .distance:
            _kilometers = State(initialValue: Int(val))
            _meters = State(initialValue: Int((val - Double(Int(val))) * 1000))
        case .calories:
            _calories = State(initialValue: Int(val))
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                pickerView
                
                Spacer()
            }
            .padding(.top)
            .background(Theme.background)
            .navigationTitle("Set \(step.durationType.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveValue()
                        dismiss()
                    }
                    .foregroundStyle(Theme.terracotta)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    @ViewBuilder
    private var pickerView: some View {
        switch step.durationType {
        case .time:
            HStack(spacing: 4) {
                Picker("Hours", selection: $hours) {
                    ForEach(0..<24) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.wheel)
                
                Text("h")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 24)
                
                Picker("Minutes", selection: $minutes) {
                    ForEach(0..<60) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.wheel)
                
                Text("m")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 24)
                
                Picker("Seconds", selection: $seconds) {
                    ForEach(0..<60) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.wheel)
                
                Text("s")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 24)
            }
            .frame(height: 180)
            .padding(.horizontal, 20)
            
        case .distance:
            HStack(spacing: 4) {
                Picker("Kilometers", selection: $kilometers) {
                    ForEach(0..<100) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.wheel)
                
                Text(unit == "km" ? "km" : "mi")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 32)
                
                Picker("Meters", selection: $meters) {
                    ForEach(stride(from: 0, through: 950, by: 50).map { $0 }, id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.wheel)
                
                Text("m")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 24)
            }
            .frame(height: 180)
            .padding(.horizontal, 20)
            
        case .calories:
            HStack(spacing: 4) {
                Picker("Calories", selection: $calories) {
                    ForEach(0..<2000) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.wheel)
                
                Text("kcal")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 48)
            }
            .frame(height: 180)
            .padding(.horizontal, 20)
        }
    }
    
    private func saveValue() {
        switch step.durationType {
        case .time:
            step.value = Double(hours * 3600 + minutes * 60 + seconds)
        case .distance:
            step.value = Double(kilometers) + Double(meters) / 1000.0
        case .calories:
            step.value = Double(calories)
        }
    }
}

struct ToggleSection<Content: View>: View {
    let title: String
    @Binding var isOn: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(title, isOn: $isOn)
                .font(.system(size: 16, weight: .medium))
                .tint(Theme.sage)
            
            if isOn {
                content()
                    .padding(.leading, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(16)
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - New Target Sheet

struct NewTargetSheet: View {
    let type: RunGoalType
    let unit: String
    let onSave: (RunTarget) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    
    // Values
    @State private var distKm: Int = 5
    @State private var distM: Int = 0
    
    @State private var timeH: Int = 0
    @State private var timeMin: Int = 30
    
    @State private var paceMin: Int = 6
    @State private var paceSec: Int = 0
    
    @State private var calories: Int = 400
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Target Name") {
                    TextField("e.g. Morning Jog", text: $name)
                }
                
                Section("Target Value") {
                    switch type {
                    case .distance:
                        HStack {
                            Picker("Km", selection: $distKm) {
                                ForEach(0..<100) { Text("\($0)").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            Text(unit)
                            
                            Picker("m", selection: $distM) {
                                ForEach(Array(stride(from: 0, to: 1000, by: 50)), id: \.self) { i in
                                    Text("\(i)").tag(i)
                                }
                            }
                            .pickerStyle(.wheel)
                            Text("m")
                        }
                        .frame(height: 120)
                        
                    case .time:
                        HStack {
                            Picker("Hours", selection: $timeH) {
                                ForEach(0..<24) { Text("\($0)").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            Text("h")
                            
                            Picker("Min", selection: $timeMin) {
                                ForEach(0..<60) { Text("\($0)").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            Text("min")
                        }
                        .frame(height: 120)
                        
                    case .pace:
                        HStack {
                            Picker("Min", selection: $paceMin) {
                                ForEach(2..<20) { Text("\($0)").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            Text("min")
                            
                            Picker("Sec", selection: $paceSec) {
                                ForEach(0..<60) { Text("\($0)").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            Text("sec")
                            
                            Text("\(unit)")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        .frame(height: 120)
                        
                    case .calories:
                        HStack {
                            TextField("Calories", value: $calories, format: .number)
                                .keyboardType(.numberPad)
                            Text("kcal")
                        }
                        
                    default:
                        EmptyView()
                    }
                }
            }
            .navigationTitle("New Target")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTarget()
                        dismiss()
                    }
                }
            }
        }
    }
    
    func saveTarget() {
        var val: Double = 0
        var secVal: Double?
        var defaultName = ""
        
        switch type {
        case .distance:
            val = Double(distKm) + (Double(distM) / 1000.0)
            defaultName = String(format: "%.1f %@", val, unit)
        case .time:
            val = Double(timeH * 3600 + timeMin * 60)
            defaultName = timeH > 0 ? "\(timeH)h \(timeMin)m" : "\(timeMin) min"
        case .pace:
            val = Double(paceMin)
            secVal = Double(paceSec)
            defaultName = String(format: "%d:%02d /%@", paceMin, paceSec, unit)
        case .calories:
            val = Double(calories)
            defaultName = "\(calories) kcal"
        default: break
        }
        
        let finalName = name.isEmpty ? defaultName : name
        let target = RunTarget(type: type, name: finalName, value: val, secondaryValue: secVal)
        onSave(target)
    }
}
