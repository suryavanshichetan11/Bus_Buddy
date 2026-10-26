//
//  Theme.swift
//  Bus Buddy
//
//  Design system colors and styles for the BusBuddy Schoolbus theme.
//  Uses a soft, warm pastel butter-yellow and cream palette that feels
//  inviting, clean, and cheerful without looking cheap or overly bright.
//

import SwiftUI

enum BusTheme {
    /// Main page background color (warm ivory/cream).
    static let pageBackground = Color(red: 0.99, green: 0.97, blue: 0.92)

    /// Warm subtle vertical gradient for full-screen pages and sheets.
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.99, green: 0.98, blue: 0.94),
            Color(red: 0.99, green: 0.95, blue: 0.88)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Card surface color — warm ivory white for crisp text readability.
    static let cardBackground = Color(red: 1.0, green: 0.995, blue: 0.985)

    /// Warm subtle card stroke border.
    static let cardBorder = Color(red: 0.94, green: 0.88, blue: 0.74).opacity(0.55)

    /// Soft warm shadow color.
    static let cardShadow = Color(red: 0.85, green: 0.76, blue: 0.58).opacity(0.14)

    /// Soft pastel schoolbus yellow tint for badges, chips, and highlights.
    static let lightYellowTint = Color(red: 1.0, green: 0.94, blue: 0.82)
    
    /// Slightly richer pastel yellow for buttons, active pills, or accents.
    static let lightYellowAccent = Color(red: 0.98, green: 0.88, blue: 0.65)
    
    /// Subtle divider/line color with warm undertone.
    static let warmLine = Color(red: 0.92, green: 0.88, blue: 0.80)
}
