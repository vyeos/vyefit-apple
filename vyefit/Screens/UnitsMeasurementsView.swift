//
//  UnitsMeasurementsView.swift
//  vyefit
//
//  Detail screen for units and measurements preferences.
//

import SwiftUI

struct UnitsMeasurementsView: View {
    private enum DistanceUnit: String, CaseIterable, Identifiable {
        case kilometers = "Kilometers"
        case miles = "Miles"

        var id: String { rawValue }
    }

    private enum WeightUnit: String, CaseIterable, Identifiable {
        case kilograms = "Kilograms"
        case pounds = "Pounds"

        var id: String { rawValue }
    }

    @AppStorage("distanceUnit") private var distanceUnit = DistanceUnit.kilometers.rawValue
    @AppStorage("weightUnit") private var weightUnit = WeightUnit.kilograms.rawValue
    @AppStorage("paceAutoMatch") private var paceAutoMatch = true

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SettingsCard("Units") {
                    VStack(alignment: .leading, spacing: 16) {
                        unitPicker(title: "Distance", selection: $distanceUnit, options: DistanceUnit.allCases)
                        unitPicker(title: "Weight", selection: $weightUnit, options: WeightUnit.allCases)
                    }
                }

                SettingsCard("Display") {
                    Toggle("Auto-match pace to distance unit", isOn: $paceAutoMatch)
                        .font(.system(size: 15, design: .serif))
                        .foregroundStyle(Theme.textPrimary)
                        .tint(Theme.sage)
                }
            }
            .padding(.vertical)
        }
        .background(Theme.background)
        .navigationTitle("Units & Measurements")
        .navigationBarTitleDisplayMode(.large)
    }

    private func unitPicker<T: Identifiable & RawRepresentable>(
        title: String,
        selection: Binding<String>,
        options: [T]
    ) -> some View where T.RawValue == String {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textSecondary)

            Picker(title, selection: selection) {
                ForEach(options) { option in
                    Text(option.rawValue)
                        .tag(option.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .tint(Theme.terracotta)
        }
    }
}

#Preview {
    NavigationStack {
        UnitsMeasurementsView()
    }
}
