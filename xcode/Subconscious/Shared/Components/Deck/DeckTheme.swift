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
        response: 0.5,
        dampingFraction: 0.825,
        blendDuration: 0
    )
    
    static let dragTargetSize = CGSize(width: 16, height: 400)
    
    static let cardPadding = AppTheme.unit * 5
    static let cornerRadius: CGFloat = 32.0
    static let cardSize = CGSize(width: 374, height: 420)
    
    static let cardShadow = Color(red: 0.45, green: 0.25, blue: 0.75)
    
    static let lightFog = Color(red: 0.93, green: 0.81, blue: 0.92)
    
    static let lightBg = LinearGradient(
        stops: [
            Gradient.Stop(color: Color(red: 0.87, green: 0.86, blue: 0.92), location: 0.00),
            Gradient.Stop(color: lightFog, location: 0.38),
            Gradient.Stop(color: Color(red: 0.92, green: 0.92, blue: 0.85), location: 1.00),
        ],
        startPoint: UnitPoint(x: 0.5, y: 0.9),
        endPoint: UnitPoint(x: 0.5, y: 0)
    )
    
    static let darkFog = Color(red: 0.2, green: 0.14, blue: 0.26)
    
    static let darkBg = LinearGradient(
        stops: [
            Gradient.Stop(color: Color(red: 0.13, green: 0.14, blue: 0.2), location: 0.00),
            Gradient.Stop(color: darkFog, location: 0.44),
            Gradient.Stop(color: Color(red: 0.1, green: 0.04, blue: 0.11), location: 1.00),
        ],
        startPoint: UnitPoint(x: 0.5, y: 0),
        endPoint: UnitPoint(x: 0.5, y: 1)
    )
    
    static let lightCardColors: [Color] = [
        Color(red: 0.97, green: 0.49, blue: 0.75),
        Color(red: 0.56, green: 0.62, blue: 0.93),
        Color(red: 0.93, green: 0.59, blue: 0.56),
        Color(red: 0.74, green: 0.52, blue: 0.95),
        Color(red: 0.97, green: 0.75, blue: 0.48)
    ]
    
    static let darkCardColors: [Color] = [
        Color(red: 0.64, green: 0.35, blue: 0.93),
        Color(red: 0.91, green: 0.37, blue: 0.35),
        Color(red: 0.72, green: 0.37, blue: 0.84),
        Color(red: 0.97, green: 0.43, blue: 0.72),
        Color(red: 0.9, green: 0.62, blue: 0.28)
    ]
}
