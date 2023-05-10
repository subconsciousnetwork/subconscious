//
//  AppTheme.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/31/22.
//

import SwiftUI

enum AppTheme {}

//  MARK: Theme units
extension AppTheme {
    static let unit: CGFloat = 4
    static let unitHalf: CGFloat = unit / 2
    static let unit2 = unit * 2
    static let unit3 = unit * 3
    static let unit4 = unit * 4
    static let padding = unit * 4
    static let tightPadding = unit * 3
    static let icon: CGFloat = unit * 6
    static let textSize: CGFloat = 16
    static let captionSize: CGFloat = 12
    // Unlike in CSS, line-spacing is not described as the total height of a
    // line. Instead, it is is measured as leading,
    // from bottom of one line to top of the next.
    // 4 + 4 = 8
    // 8 + 16 = 24
    // 8 * 1.5 = 24
    // 2021-12-10 Gordon Brander
    static let lineSpacing: CGFloat = 4
    static let lineHeight: CGFloat = 24
    static let fabSize: CGFloat = 56
    static let minTouchSize: CGFloat = 44
    static let cornerRadius: Double = 8
    static let cornerRadiusLg: Double = 16
    
    static let brandMark = Image("sub_logo")
    
    static let defaultRowButtonInsets =
        EdgeInsets(
            top: AppTheme.unit2,
            leading: AppTheme.unit4,
            bottom: AppTheme.unit2,
            trailing: AppTheme.unit4
        )
}

//  MARK: UIFonts
//  Note you can convert from UIFont to Font easily, but you can't yet convert
//  from Font to UIFont. So, we define our fonts as UIFonts.
//  2021-12-15 Gordon Brander
extension UIFont {
    static let appTextMono = UIFont(
        name: "IBMPlexMono",
        size: AppTheme.textSize
    )!

    static let appTextMonoBold = UIFont(
        name: "IBMPlexMono-Bold",
        size: AppTheme.textSize
    )!

    static let appTextMonoItalic = UIFont(
        name: "IBMPlexMono-Italic",
        size: AppTheme.textSize
    )!
}

//  MARK: Color
extension Color {
    static let separator = SwiftUI.Color(uiColor: UIColor.separator)
    static let placeholderText = SwiftUI.Color(
        uiColor: UIColor.placeholderText
    )
    static let disabled = placeholderText
    static let tertiaryLabel = SwiftUI.Color(uiColor: .tertiaryLabel)
    static let icon = SwiftUI.Color.accentColor
    static let secondaryIcon = SwiftUI.Color.secondary
    static let tertiaryIcon = SwiftUI.Color(
        uiColor: UIColor.tertiarySystemFill
    )
    static let buttonText = SwiftUI.Color.accentColor
    /// Fill for pressed-state overlays
    static let background = SwiftUI.Color(uiColor: UIColor.systemBackground)
    static let secondaryBackground = SwiftUI.Color(
        uiColor: UIColor.secondarySystemBackground
    )
    static let formFieldBackground = SwiftUI.Color(
        uiColor: UIColor.secondarySystemGroupedBackground
    )
    static let backgroundPressed = SwiftUI.Color(UIColor.systemFill)
    static let inputBackground = SwiftUI.Color(uiColor: .secondarySystemFill)
    static let primaryButtonBackground = Color.accentColor.opacity(0.2)
    static let primaryButtonBackgroundPressed = primaryButtonBackground
        .opacity(0.5)
    static let primaryButtonBackgroundDisabled = primaryButtonBackground
        .opacity(0.3)
    static let primaryButtonText = SwiftUI.Color.accentColor
    static let primaryButtonTextPressed = primaryButtonText.opacity(0.5)
    static let primaryButtonTextDisabled = primaryButtonText.opacity(0.3)
    static let fabBackground = primaryButtonBackground
    static let fabBackgroundPressed = primaryButtonBackgroundPressed
    static let fabText = Color.white
    static let fabTextPressed = fabText.opacity(0.5)
    static let fabTextDisabled = fabText.opacity(0.3)
    static let scrim = SwiftUI.Color(UIColor.tertiarySystemFill)
    
    // MARK: Brand colours
    // Brand Mark
    static let brandMarkPink = Color(red: 255/255, green: 163/255, blue: 186/255, opacity: 1) // #FFA3BA
    static let brandMarkViolet = Color(red: 197/255, green: 112/255, blue: 219/255, opacity: 1) // #C570DB
    static let brandMarkCyan = Color(red: 48/255, green: 255/255, blue: 233/255, opacity: 1) // #30FFE9
    static let brandMarkRed = Color(red: 255/255, green: 94/255, blue: 135/255, opacity: 1) // #FF5E87
    static let brandMarkPurple = Color(red: 132/255, green: 42/255, blue: 156/255, opacity: 1) // #842A9C
    
    // BG
    static let brandBgBlush = Color(red: 237/255, green: 207/255, blue: 234/255, opacity: 1) // #EDCFEA
    static let brandBgGrey = Color(red: 223/255, green: 219/255, blue: 235/255, opacity: 1) // #DFDBEB
    static let brandBgTan = Color(red: 235/255, green: 235/255, blue: 218/255, opacity: 1) // #EBEBDA
    static let brandBgPurple = Color(red: 71/255, green: 30/255, blue: 68/255, opacity: 1) // #471E44
    static let brandBgBlack = Color(red: 35/255, green: 31/255, blue: 32/255, opacity: 1) // #231F20
    static let brandBgSlate = Color(red: 57/255, green: 50/255, blue: 84/255, opacity: 1) // #393254
    
    static func brandGradient(a: Color, b: Color, c: Color) -> [Gradient.Stop] {
        [
            Gradient.Stop(color: a, location: 0),
            Gradient.Stop(color: b, location: 0.50),
            Gradient.Stop(color: b, location: 0.60),
            Gradient.Stop(color: c, location: 0.95)
        ]
    }
    
    static let brandDarkMarkGradient = brandGradient(
        a: Color.brandMarkPink,
        b: Color.brandMarkViolet,
        c: Color.brandMarkCyan
    )
    
    static let brandLightMarkGradient = brandGradient(
        a: Color.brandMarkRed,
        b: Color.brandMarkPurple,
        c: Color.brandMarkCyan
    )
    
    static func brandGradient(_ colorScheme: ColorScheme) -> [Gradient.Stop] {
        colorScheme == .dark ? Color.brandDarkMarkGradient : Color.brandLightMarkGradient
    }
    
    static func brandInnerShadow(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.brandMarkPurple : Color.brandMarkPink
    }
    
    static func brandText(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.brandBgBlack : Color.white
    }
    
    static func brandDropShadow(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.brandMarkPink : Color.brandMarkPurple
    }
}
