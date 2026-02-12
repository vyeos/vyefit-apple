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
    @Environment(RunStore.self) private var runStore
    
    // State
    private let store = RunTargetStore.shared
    @State private var selectedTarget: RunTarget?
    @State private var showNewTargetSheet = false
    @State private var selectedZone: HeartRateZone?
    
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
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        if type == .intervals {
                            IntervalBuilderView(workout: $intervalWorkout, unit: unitString)
                        } else if type == .heartRate {
                            HeartRateZonePicker(selectedZone: $selectedZone)
                        } else if type != .quickStart {
                            // Standard Targets (Distance, Time, Pace, Calories)
                            targetSelectionView
                        } else {
                            // Quick Start
                            Text("Ready to run? Just hit start.")
                                .font(.system(size: 16))
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.top, 40)
                        }
                    }
                    .padding(20)
                }
                
                // Footer / Start Button
                VStack(spacing: 12) {
                    Divider()
                    
                    if runStore.activeSession != nil {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                            Text("A run is already in progress")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(Theme.terracotta)
                        .padding(.horizontal, 20)
                    }
                    
                    Button {
                        startRun()
                        dismiss()
                    } label: {
                        Text(runStore.activeSession != nil ? "Run in Progress" : "Start Run")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(runStore.activeSession != nil ? Theme.textSecondary.opacity(0.5) : Theme.terracotta)
                            .clipShape(Capsule())
                    }
                    .disabled(runStore.activeSession != nil)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(Theme.background)
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
        .presentationDetents([.large])
    }
    
    private func startRun() {
        var config: RunConfiguration
        
        switch type {
        case .quickStart:
            config = RunConfiguration(type: .quickStart)
        case .distance:
            config = RunConfiguration(type: .distance, targetValue: selectedTarget?.value)
        case .time:
            config = RunConfiguration(type: .time, targetValue: selectedTarget?.value)
        case .pace:
            let paceValue = (selectedTarget?.value ?? 0) * 60 + (selectedTarget?.secondaryValue ?? 0)
            config = RunConfiguration(type: .pace, targetValue: selectedTarget?.value, targetPace: paceValue)
        case .calories:
            config = RunConfiguration(type: .calories, targetValue: selectedTarget?.value)
        case .heartRate:
            config = RunConfiguration(type: .heartRate, targetZone: selectedZone?.id)
        case .intervals:
            config = RunConfiguration(type: .intervals, intervalWorkout: intervalWorkout)
        }
        
        runStore.startSession(configuration: config)
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
                .foregroundStyle(isSelected ? .white : Theme.textPrimary)
                .lineLimit(1)
            
            if target.type != .pace { // Pace usually has name = value description
                Text(displayValue)
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : Theme.textSecondary)
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
    
    var body: some View {
        VStack(spacing: 24) {
            // Warmup
            ToggleSection(title: "Warmup", isOn: $workout.warmupEnabled) {
                HStack {
                    Text("Duration")
                    Spacer()
                    Text(formatTime(workout.warmupDuration))
                }
            }
            
            // Loop Section
            VStack(spacing: 16) {
                HStack {
                    Text("Interval Loop")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Stepper("\(workout.repeats)x", value: $workout.repeats, in: 1...20)
                        .font(.system(size: 16, weight: .medium))
                }
                
                VStack(spacing: 12) {
                    IntervalStepRow(step: $workout.workStep, label: "Work", color: Theme.terracotta, unit: unit)
                    IntervalStepRow(step: $workout.restStep, label: "Rest", color: Theme.sage, unit: unit)
                }
                .padding(16)
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            // Cooldown
            ToggleSection(title: "Cooldown", isOn: $workout.cooldownEnabled) {
                HStack {
                    Text("Duration")
                    Spacer()
                    Text(formatTime(workout.cooldownDuration))
                }
            }
        }
    }
    
    func formatTime(_ seconds: Double) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct IntervalStepRow: View {
    @Binding var step: IntervalStep
    let label: String
    let color: Color
    let unit: String
    
    var body: some View {
        HStack {
            Capsule()
                .fill(color)
                .frame(width: 4, height: 24)
            
            Text(label)
                .font(.system(size: 15, weight: .medium))
            
            Spacer()
            
            Menu {
                Picker("Type", selection: $step.durationType) {
                    ForEach(IntervalDurationType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            } label: {
                Text(step.durationType.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.terracotta)
            }
            
            // Value Input Placeholder (Would be a picker/textfield)
            Text(formatValue(step))
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.background)
                .cornerRadius(6)
        }
    }
    
    func formatValue(_ step: IntervalStep) -> String {
        if step.durationType == .time {
            let m = Int(step.value) / 60
            let s = Int(step.value) % 60
            return String(format: "%d:%02d", m, s)
        } else {
            return String(format: "%.2f %@", step.value, unit)
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
