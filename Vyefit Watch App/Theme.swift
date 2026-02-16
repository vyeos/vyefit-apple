//
//  Theme.swift
//  Vyefit Watch App
//
//  Color palette for the Soft Natural aesthetic - WatchOS version.
//

import SwiftUI

enum Theme {
    // MARK: - Base Colors
    static let terracotta = Color(red: 0.80, green: 0.45, blue: 0.35)
    static let sage = Color(red: 0.55, green: 0.65, blue: 0.50)
    static let stone = Color(red: 0.75, green: 0.70, blue: 0.64)
    static let bark = Color(red: 0.30, green: 0.25, blue: 0.22)
    static let clay = Color(red: 0.65, green: 0.40, blue: 0.35)
    static let moss = Color(red: 0.45, green: 0.50, blue: 0.40)
    
    // MARK: - Semantic Colors
    static let heartRate = terracotta
    static let calories = clay
    static let time = stone
    static let success = sage
    static let warning = clay
    static let error = terracotta
    
    // MARK: - Schedule Type Colors
    static var restDay: Color { stone.opacity(0.6) }
    static var busyDay: Color { clay.opacity(0.7) }
    
    // MARK: - Watch App Colors
    static let watchBackgroundTop = Color(red: 0.15, green: 0.14, blue: 0.12)
    static let watchBackgroundBottom = Color(red: 0.10, green: 0.09, blue: 0.08)
    static let watchCardBackground = Color.white.opacity(0.08)
    static let watchTextPrimary = Color.white
    static let watchTextSecondary = Color.white.opacity(0.7)
    static let watchTextTertiary = Color.white.opacity(0.5)
    static let watchAccent = terracotta
    static let watchSuccess = sage
    static let watchStop = clay
    
    // MARK: - Shared Colors (Watch uses dark mode values)
    static var sand: Color {
        Color(red: 0.96, green: 0.93, blue: 0.88)
    }

    static var cream: Color {
        Color(red: 0.99, green: 0.97, blue: 0.94)
    }

    static var textPrimary: Color {
        Color(red: 0.95, green: 0.93, blue: 0.90)
    }

    static var textSecondary: Color {
        Color(red: 0.72, green: 0.69, blue: 0.63)
    }

    static var background: Color {
        Color(red: 0.10, green: 0.09, blue: 0.08)
    }

    static var cardBackground: Color {
        Color(red: 0.17, green: 0.16, blue: 0.15)
    }
}
