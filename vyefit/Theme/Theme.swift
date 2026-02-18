//
//  Theme.swift
//  vyefit
//
//  Color palette for the Soft Natural aesthetic.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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
    
    #if canImport(UIKit)
    private static let sandLight = UIColor(red: 0.96, green: 0.93, blue: 0.88, alpha: 1)
    private static let creamLight = UIColor(red: 0.99, green: 0.97, blue: 0.94, alpha: 1)
    private static let darkBackground = UIColor(red: 0.10, green: 0.09, blue: 0.08, alpha: 1)
    private static let darkSurface = UIColor(red: 0.17, green: 0.16, blue: 0.15, alpha: 1)
    private static let lightTextPrimary = UIColor(red: 0.20, green: 0.18, blue: 0.15, alpha: 1)
    private static let lightTextSecondary = UIColor(red: 0.50, green: 0.47, blue: 0.42, alpha: 1)
    private static let darkTextPrimary = UIColor(red: 0.95, green: 0.93, blue: 0.90, alpha: 1)
    private static let darkTextSecondary = UIColor(red: 0.72, green: 0.69, blue: 0.63, alpha: 1)

    static var sand: Color {
        dynamicColor(light: sandLight, dark: darkSurface)
    }

    static var cream: Color {
        dynamicColor(light: creamLight, dark: darkSurface)
    }

    static var textPrimary: Color {
        dynamicColor(light: lightTextPrimary, dark: darkTextPrimary)
    }

    static var textSecondary: Color {
        dynamicColor(light: lightTextSecondary, dark: darkTextSecondary)
    }

    static var background: Color {
        dynamicColor(light: UIColor(red: 0.97, green: 0.95, blue: 0.92, alpha: 1), dark: darkBackground)
    }

    static var cardBackground: Color {
        dynamicColor(light: UIColor(red: 0.99, green: 0.97, blue: 0.94, alpha: 1), dark: darkSurface)
    }

    private static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
    #else
    // WatchOS fallback colors
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
    #endif
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch cleaned.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
