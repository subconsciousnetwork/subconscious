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
    static let cardContentSize = CGSize(width: 374, height: AppTheme.unit * 80)
    
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
    
    static let cardHeaderTint = Color.brandMarkPink.opacity(0.025)
}

public enum ThemeColor: Int, Hashable, CaseIterable {
    case a = 0
    case b = 1
    case c = 2
    case d = 3
    case e = 4
}

public extension Color {
    static var cardThemeColorA: Color {
        Color("CardThemeColorA")
    }
    static var cardThemeColorB: Color {
        Color("CardThemeColorB")
    }
    static var cardThemeColorC: Color {
        Color("CardThemeColorC")
    }
    static var cardThemeColorD: Color {
        Color("CardThemeColorD")
    }
    static var cardThemeColorE: Color {
        Color("CardThemeColorE")
    }
    
    static var cardThemeHighlightColorA: Color {
        Color("CardThemeHighlightColorA")
    }
    static var cardThemeHighlightColorB: Color {
        Color("CardThemeHighlightColorB")
    }
    static var cardThemeHighlightColorC: Color {
        Color("CardThemeHighlightColorC")
    }
    static var cardThemeHighlightColorD: Color {
        Color("CardThemeHighlightColorD")
    }
    static var cardThemeHighlightColorE: Color {
        Color("CardThemeHighlightColorE")
    }
}

public extension ThemeColor {
    func toColor() -> Color {
        switch self {
        case .a:
            return .cardThemeColorA
        case .b:
            return .cardThemeColorB
        case .c:
            return .cardThemeColorC
        case .d:
            return .cardThemeColorD
        case .e:
            return .cardThemeColorE
        }
    }
    
    func toHighlightColor() -> Color {
        switch self {
        case .a:
            return .cardThemeHighlightColorA
        case .b:
            return .cardThemeHighlightColorB
        case .c:
            return .cardThemeHighlightColorC
        case .d:
            return .cardThemeHighlightColorD
        case .e:
            return .cardThemeHighlightColorE
        }
    }
}

private extension Hashable {
    var themeColor: ThemeColor {
        let colors = ThemeColor.allCases
        return colors[abs(self.hashValue) % colors.count]
    }
}

extension Slashlink {
    var themeColor: ThemeColor {
        description.themeColor
    }
}

extension EntryStub {
    var color: Color {
        self.headers.themeColor?.toColor()
            ?? self.address.themeColor.toColor()
    }
    
    var highlightColor: Color {
        self.headers.themeColor?.toHighlightColor()
            ?? self.address.themeColor.toHighlightColor()
    }
}
