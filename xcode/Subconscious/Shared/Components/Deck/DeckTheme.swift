//
//  DeckTheme.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 22/11/2023.
//

import SwiftUI

enum DeckTheme {}
extension DeckTheme {
    static let reboundSpring: Animation = .spring(
        response: 0.25,
        dampingFraction: 0.5,
        blendDuration: 0
    )
    
    static let dragTargetSize = CGSize(width: 16, height: 400)
    
    static let cardPadding = AppTheme.unit * 5
    static let cornerRadius: CGFloat = 32.0
    static let cardSize = CGSize(width: 374, height: 420)
    
    static let cardShadow = Color(red: 0.19, green: 0.09, blue: 0.33)
    
    static let lightBgStart = Color(red: 0.92, green: 0.92, blue: 0.85)
    static let lightBgMid = Color(red: 0.93, green: 0.81, blue: 0.92)
    static let lightBgEnd = Color(red: 0.87, green: 0.86, blue: 0.92)
    
    static let lightBg = LinearGradient(
        stops: [
            Gradient.Stop(color: lightBgStart, location: 0.00),
            Gradient.Stop(color: lightBgMid, location: 0.38),
            Gradient.Stop(color: lightBgEnd, location: 1.00),
        ],
        startPoint: UnitPoint(x: 0.5, y: 0),
        endPoint: UnitPoint(x: 0.5, y: 1)
    )
    
    static let darkBgStart = Color(red: 0.13, green: 0.14, blue: 0.2)
    static let darkBgMid = Color(red: 0.2, green: 0.14, blue: 0.26)
    static let darkBgEnd = Color(red: 0.1, green: 0.04, blue: 0.11)
    
    static let darkBg = LinearGradient(
        stops: [
            Gradient.Stop(color: darkBgStart, location: 0.00),
            Gradient.Stop(color: darkBgMid, location: 0.44),
            Gradient.Stop(color: darkBgEnd, location: 1.00),
        ],
        startPoint: UnitPoint(x: 0.5, y: 0),
        endPoint: UnitPoint(x: 0.5, y: 1)
    )
    
    static let lightCardColors: [Color] = [
        Color(red: 0.98, green: 0.96, blue: 0.94),
        Color(red: 0.92, green: 0.98, blue: 0.97),
        Color(red: 0.97, green: 0.93, blue: 0.97),
        Color(red: 0.98, green: 0.92, blue: 0.94),
        Color(red: 0.93, green: 0.94, blue: 0.97)
    ]
    
    static let lightCardHighlightColors: [Color] = [
        Color(red: 0.73, green: 0.62, blue: 0.45),
        Color(red: 0.36, green: 0.71, blue: 0.66),
        Color(red: 0.66, green: 0.41, blue: 0.64),
        Color(red: 0.71, green: 0.36, blue: 0.45),
        Color(red: 0.39, green: 0.48, blue: 0.66)
    ]
    
    static let darkCardColors: [Color] = [
        Color(red: 0.7, green: 0.55, blue: 0.4),
        Color(red: 0.4, green: 0.7, blue: 0.64),
        Color(red: 0.73, green: 0.49, blue: 0.71),
        Color(red: 0.78, green: 0.44, blue: 0.53),
        Color(red: 0.47, green: 0.55, blue: 0.73)
    ]
    
    static let darkCardHighlightColors: [Color] = [
        Color(red: 1, green: 0.87, blue: 0.68),
        Color(red: 0.68, green: 1, blue: 1),
        Color(red: 1, green: 0.79, blue: 1),
        Color(red: 1, green: 0.74, blue: 0.85),
        Color(red: 0.77, green: 0.88, blue: 1)
    ]
}

private extension Hashable {
    private func colors(colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark
            ? DeckTheme.darkCardColors
            : DeckTheme.lightCardColors
    }
    
    private func highlightColors(colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark
            ? DeckTheme.darkCardHighlightColors
            : DeckTheme.lightCardHighlightColors
    }
    
    func color(colorScheme: ColorScheme) -> Color {
        let colors = colors(colorScheme: colorScheme)
        return colors[abs(self.hashValue) % colors.count]
    }
    
    func highlightColor(colorScheme: ColorScheme) -> Color {
        let colors = highlightColors(colorScheme: colorScheme)
        return colors[abs(self.hashValue) % colors.count]
    }
}

extension Slashlink {
    func color(colorScheme: ColorScheme) -> Color {
        description.color(colorScheme: colorScheme)
    }
    
    func highlightColor(colorScheme: ColorScheme) -> Color {
        description.highlightColor(colorScheme: colorScheme)
    }
}


extension EntryStub {
    func color(colorScheme: ColorScheme) -> Color {
        address.color(colorScheme: colorScheme)
    }
    
    func highlightColor(colorScheme: ColorScheme) -> Color {
        address.highlightColor(colorScheme: colorScheme)
    }
}
