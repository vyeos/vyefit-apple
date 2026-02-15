//
//  SessionDetailView.swift
//  vyefit
//
//  Comprehensive session analysis view for runs and workouts.
//

import SwiftUI
import Charts
import MapKit

struct SessionDetailView: View {
    let runSession: RunSessionRecord?
    let workoutSession: WorkoutSessionRecord?
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage("distanceUnit") private var distanceUnit = "Kilometers"
    @State private var showHeartRateDetails = false
    @State private var showDeleteConfirmation = false
    
    private var isRun: Bool { runSession != nil }
    private var sessionName: String {
        runSession?.name ?? workoutSession?.name ?? "Session"
    }
    private var sessionDate: Date {
        runSession?.date ?? workoutSession?.date ?? Date()
    }
    private var location: String {
        runSession?.location ?? workoutSession?.location ?? "Unknown"
    }
    private var duration: TimeInterval {
        runSession?.duration ?? workoutSession?.duration ?? 0
    }
    private var calories: Int {
        runSession?.calories ?? workoutSession?.calories ?? 0
    }
    private var heartRateAvg: Int {
        runSession?.heartRateAvg ?? workoutSession?.heartRateAvg ?? 0
    }
    private var heartRateMax: Int {
        runSession?.heartRateMax ?? workoutSession?.heartRateMax ?? 0
    }
    private var heartRateData: [HeartRateDataPoint] {
        runSession?.heartRateData ?? workoutSession?.heartRateData ?? []
    }
    private var wasPaused: Bool {
        runSession?.wasPaused ?? workoutSession?.wasPaused ?? false
    }
    private var totalElapsedTime: TimeInterval? {
        runSession?.totalElapsedTime ?? workoutSession?.totalElapsedTime
    }
    private var workingTime: TimeInterval? {
        runSession?.workingTime ?? workoutSession?.workingTime
    }
    
    init(runSession: RunSessionRecord) {
        self.runSession = runSession
        self.workoutSession = nil
    }
    
    init(workoutSession: WorkoutSessionRecord) {
        self.runSession = nil
        self.workoutSession = workoutSession
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Pause Info (if applicable)
                if wasPaused, let total = totalElapsedTime, let working = workingTime {
                    pauseInfoSection(total: total, working: working)
                }
                
                // Main Stats Grid
                mainStatsSection
                
                // Heart Rate Graph
                heartRateSection
                
                // Run-specific sections
                if isRun, let run = runSession {
                    // Map
                    mapSection(run: run)
                    
                    // Run Stats
                    runStatsSection(run: run)
                    
                    // Splits
                    if !run.splits.isEmpty {
                        splitsSection(run: run)
                    }
                }
                
                // Workout-specific sections
                if !isRun, let workout = workoutSession {
                    workoutSessionSection(session: workout)
                }
            }
            .padding(.vertical, 20)
        }
        .background(Theme.background)
        .navigationTitle("Session Details")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Text("Delete")
                }
            }
        }
        .alert("Delete Session?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteSession()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove the session from Vyefit and attempt to delete it from Apple Health.")
        }
    }

    private func deleteSession() {
        if let runSession {
            HistoryStore.shared.deleteRun(id: runSession.id)
            HealthKitManager.shared.deleteWorkout(uuid: runSession.id) { _ in }
        } else if let workoutSession {
            HistoryStore.shared.deleteWorkout(id: workoutSession.id)
            HealthKitManager.shared.deleteWorkout(uuid: workoutSession.id) { _ in }
        }
        dismiss()
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(sessionName)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(Theme.textPrimary)
            
            // Date and time on separate lines
            VStack(alignment: .leading, spacing: 4) {
                Label(sessionDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
                
                Label(sessionDate.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
                
                Label(location, systemImage: "mappin.and.ellipse")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
            }
            
            HStack(spacing: 8) {
                Image(systemName: isRun ? "figure.run" : "figure.strengthtraining.traditional")
                    .font(.system(size: 14))
                Text(isRun ? "Run" : "Workout")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(isRun ? Theme.sage : Theme.terracotta)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background((isRun ? Theme.sage : Theme.terracotta).opacity(0.15))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }
    
    private func pauseInfoSection(total: TimeInterval, working: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pause.circle.fill")
                    .foregroundStyle(Theme.stone)
                Text("Session Paused")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
            }
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Time")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                    Text(formatDuration(total))
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Working Time")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                    Text(formatDuration(working))
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.sage)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Paused")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                    Text(formatDuration(total - working))
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.stone)
                }
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
    
    private var mainStatsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(title: "Duration", value: formatDuration(duration), icon: "clock", color: Theme.terracotta)
            StatCard(title: "Calories", value: "\(calories)", unit: "kcal", icon: "flame.fill", color: Theme.terracotta)
            StatCard(title: "Avg HR", value: "\(heartRateAvg)", unit: "bpm", icon: "heart.fill", color: Theme.terracotta)
        }
        .padding(.horizontal, 20)
    }
    
    private var heartRateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if #available(iOS 16.0, *), !heartRateData.isEmpty {
                let minHRValue = heartRateData.map { $0.heartRate }.min() ?? 60
                let maxHRValue = heartRateData.map { $0.heartRate }.max() ?? 180
                let startTime = sessionDate
                
                // Create time-based x values
                let chartData = heartRateData.map { point -> (time: Date, hr: Int, isMin: Bool, isMax: Bool) in
                    let time = startTime.addingTimeInterval(point.timestamp)
                    let isMin = point.heartRate == minHRValue
                    let isMax = point.heartRate == maxHRValue
                    return (time: time, hr: point.heartRate, isMin: isMin, isMax: isMax)
                }
                
                GeometryReader { geometry in
                    ZStack {
                        // Chart takes full width
                        Chart(chartData, id: \.time) { dataPoint in
                            RuleMark(
                                x: .value("Time", dataPoint.time),
                                yStart: .value("Min", minHRValue - 5),
                                yEnd: .value("HR", dataPoint.hr)
                            )
                            .foregroundStyle(barColor(for: dataPoint.hr, isMin: dataPoint.isMin, isMax: dataPoint.isMax))
                            .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                        .chartYAxis(.hidden)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                                AxisValueLabel(anchor: .top) {
                                    if let date = value.as(Date.self) {
                                        Text(date, format: .dateTime.hour().minute())
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(Theme.textSecondary)
                                    }
                                }
                            }
                        }
                        .chartYScale(domain: (minHRValue - 10)...(maxHRValue + 10))
                        .frame(width: geometry.size.width, height: 140)
                        
                        // Max HR label overlay (top right)
                        VStack {
                            HStack {
                                Spacer()
                                Text("\(maxHRValue)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.terracotta)
                                    .padding(.trailing, 4)
                            }
                            Spacer()
                        }
                        
                        // Min HR label overlay (bottom right)
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("\(minHRValue)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.sage)
                                    .padding(.trailing, 4)
                                    .padding(.bottom, 20)
                            }
                        }
                    }
                }
                .frame(height: 160)
                
                // Average BPM
                HStack {
                    Text("\(heartRateAvg) BPM AVG")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.terracotta)
                    Spacer()
                }
            } else {
                // Fallback for iOS 15 or empty data
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "heart.text.square")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.stone.opacity(0.5))
                        Text("Heart rate data unavailable")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                }
                .frame(height: 140)
            }
            
            // Show Details Button
            Button {
                showHeartRateDetails = true
            } label: {
                HStack {
                    Text("Show Heart Rate Details")
                        .font(.system(size: 15, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                }
								.foregroundStyle(Theme.stone)
                .padding(.horizontal, 4)
            }
            .sheet(isPresented: $showHeartRateDetails) {
                HeartRateDetailView(
                    heartRateData: heartRateData,
                    heartRateAvg: heartRateAvg,
                    heartRateMax: heartRateMax,
                    startTime: sessionDate,
                    duration: duration
                )
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
    
    private func mapSection(run: RunSessionRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Route")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                
                Spacer()
                
                let distanceStr = distanceUnit == "Kilometers" 
                    ? String(format: "%.2f km", run.distance)
                    : String(format: "%.2f mi", run.distance * 0.621371)
                Text(distanceStr)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.sage)
            }
            
            // Actual MapKit Map
            RouteMapView(route: run.route)
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
    
    private func runStatsSection(run: RunSessionRecord) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Run Stats")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                let paceUnit = distanceUnit == "Kilometers" ? "min/km" : "min/mi"
                let paceValue = distanceUnit == "Kilometers" ? run.avgPace : run.avgPace * 1.60934
                
                StatCard(
                    title: "Avg Pace",
                    value: formatPace(paceValue),
                    unit: paceUnit,
                    icon: "speedometer",
                    color: Theme.sage
                )
                
                let distValue = distanceUnit == "Kilometers" ? run.distance : run.distance * 0.621371
                let distUnit = distanceUnit == "Kilometers" ? "km" : "mi"
                StatCard(
                    title: "Distance",
                    value: String(format: "%.2f", distValue),
                    unit: distUnit,
                    icon: "map",
                    color: Theme.sage
                )
                
                StatCard(
                    title: "Elevation +",
                    value: String(format: "%.0f", run.elevationGain),
                    unit: "m",
                    icon: "arrow.up.forward",
                    color: Theme.sage
                )
                
                StatCard(
                    title: "Elevation -",
                    value: String(format: "%.0f", run.elevationLoss),
                    unit: "m",
                    icon: "arrow.down.forward",
                    color: Theme.sage
                )
                
                StatCard(
                    title: "Avg Cadence",
                    value: "\(run.avgCadence)",
                    unit: "spm",
                    icon: "figure.walk.motion",
                    color: Theme.sage
                )
                
                StatCard(
                    title: "Max HR",
                    value: "\(run.heartRateMax)",
                    unit: "bpm",
                    icon: "bolt.heart",
                    color: Theme.sage
                )
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
    
    private func splitsSection(run: RunSessionRecord) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            let paceUnit = distanceUnit == "Kilometers" ? "min/km" : "min/mi"
            
            Text("Splits")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.textPrimary)
            
            VStack(spacing: 8) {
                // Header
                HStack {
                    Text(distanceUnit == "Kilometers" ? "KM" : "MI")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 40, alignment: .leading)
                    
                    Spacer()
                    
                    Text("Pace (\(paceUnit))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                    
                    Spacer()
                    
                    Text("Elev")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 60, alignment: .trailing)
                }
                .padding(.horizontal, 12)
                
                Divider()
                    .background(Theme.stone.opacity(0.2))
                
                ForEach(run.splits) { split in
                    HStack {
                        Text("\(split.kilometer)")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(width: 40, alignment: .leading)
                        
                        Spacer()
                        
                        let paceValue = distanceUnit == "Kilometers" ? split.pace : split.pace * 1.60934
                        Text(formatPace(paceValue))
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: split.elevationChange >= 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 10))
                            Text("\(Int(abs(split.elevationChange)))m")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(split.elevationChange >= 0 ? Theme.sage : Theme.terracotta)
                        .frame(width: 60, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(split.kilometer % 2 == 0 ? Theme.stone.opacity(0.05) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
    
    private func workoutSessionSection(session: WorkoutSessionRecord) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.textPrimary)
            
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.terracotta.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.terracotta)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.workoutTemplateName ?? session.name)
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Text("\(session.exerciseCount) exercises")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hrs = Int(seconds) / 3600
        let mins = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        }
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func formatPace(_ pace: Double) -> String {
        let mins = Int(pace)
        let secs = Int((pace - Double(mins)) * 60)
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func heartRateColor(for hr: Int) -> Color {
        if hr < 120 { return Theme.sage }
        if hr < 150 { return Theme.terracotta }
        return Theme.error
    }
    
    private func barColor(for hr: Int, isMin: Bool, isMax: Bool) -> Color {
        if isMax { return Theme.terracotta }
        if isMin { return Theme.sage }
        return Theme.stone.opacity(0.6)
    }
    
    private func formatTimeLabel(_ minutes: Double) -> String {
        let mins = Int(minutes)
        let hrs = mins / 60
        let remainingMins = mins % 60
        
        if hrs > 0 {
            return "\(hrs)h \(remainingMins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Heart Rate Detail View

struct HeartRateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    let heartRateData: [HeartRateDataPoint]
    let heartRateAvg: Int
    let heartRateMax: Int
    let startTime: Date
    let duration: TimeInterval
    
    private var zoneTimes: [(zone: HeartRateZone, time: TimeInterval)] {
        var times: [Int: TimeInterval] = [:]
        
        for i in 0..<heartRateData.count {
            let hr = heartRateData[i].heartRate
            let zone = HeartRateZone.defaults.first { hr >= $0.minBPM && hr <= $0.maxBPM } ?? HeartRateZone.defaults.first!
            
            let timeInZone: TimeInterval
            if i < heartRateData.count - 1 {
                timeInZone = heartRateData[i + 1].timestamp - heartRateData[i].timestamp
            } else {
                timeInZone = 30 // Last point, assume 30 seconds
            }
            
            times[zone.id, default: 0] += timeInZone
        }
        
        return HeartRateZone.defaults.map { zone in
            (zone: zone, time: times[zone.id] ?? 0)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Avg HR Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Avg. Heart Rate")
                            .font(.system(size: 17))
                            .foregroundStyle(Theme.textSecondary)
                        Text("\(heartRateAvg)BPM")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.terracotta)
                    }
                    .padding(.horizontal)
                    

                    
                    // Zone Breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(zoneTimes, id: \.zone.id) { item in
                            ZoneRow(
                                zone: item.zone,
                                time: item.time,
                                totalTime: duration
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Footer text
                    Text("Estimated time in each heart rate zone.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Theme.background)
            .navigationTitle("Heart Rate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.terracotta)
                }
            }
        }
    }
    
}

struct ZoneRow: View {
    let zone: HeartRateZone
    let time: TimeInterval
    let totalTime: TimeInterval
    
    private var formattedTime: String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var percentage: Double {
        totalTime > 0 ? (time / totalTime) * 100 : 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text("Zone \(zone.id)")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(zone.color)
                    .frame(width: 70, alignment: .leading)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.stone.opacity(0.2))
                            .frame(height: 8)
                        
                        if percentage > 0 {
                            Capsule()
                                .fill(zone.color)
                                .frame(width: max(4, geometry.size.width * CGFloat(percentage / 100)), height: 8)
                        }
                    }
                }
                .frame(height: 8)
                
                Text(formattedTime)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 70, alignment: .trailing)
            }
            
            HStack {
                Spacer()
                Text("\(zone.minBPM)-\(zone.maxBPM)BPM")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    var unit: String? = nil
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
            
            if let unit = unit {
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            } else {
                // Empty spacer to maintain consistent height
                Text(" ")
                    .font(.system(size: 11))
                    .opacity(0)
            }
            
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding(.vertical, 16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RouteMapView: View {
    let route: [MapCoordinate]
    
    var body: some View {
        Map {
            if route.count > 1 {
                // Draw the route as a polyline
                MapPolyline(coordinates: route.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) })
                    .stroke(Theme.sage, lineWidth: 4)
            }
            
            // Start marker
            if let first = route.first {
                Marker("Start", coordinate: CLLocationCoordinate2D(latitude: first.latitude, longitude: first.longitude))
                    .tint(Theme.sage)
            }
            
            // End marker
            if let last = route.last {
                Marker("Finish", coordinate: CLLocationCoordinate2D(latitude: last.latitude, longitude: last.longitude))
                    .tint(Theme.terracotta)
            }
        }
        .mapStyle(.standard)
    }
}
