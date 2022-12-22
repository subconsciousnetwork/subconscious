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
    static let cornerRadius: Double = 8
    static let cornerRadiusLg: Double = 16
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
//  String color names are references to ColorSet assets, and can be found
//  in Assets.xassets. Each ColorSet contains a light and dark mode, and color
//  is resolved at runtime.
//  2021-12-15 Gordon Brander
extension Color {
    static let text = SwiftUI.Color("TextColor")
    static let placeholderText = SwiftUI.Color("PlaceholderTextColor")
    static let textPressed = text.opacity(0.5)
    static let textDisabled = placeholderText
    static let secondaryText = SwiftUI.Color("SecondaryTextColor")
    static let tertiaryText = placeholderText
    static let icon = SwiftUI.Color.accentColor
    static let secondaryIcon = SwiftUI.Color.secondaryText
    static let tertiaryIcon = SwiftUI.Color(UIColor.tertiarySystemFill)
    static let buttonText = SwiftUI.Color.accentColor
    /// Fill for pressed-state overlays
    static let pressedFill = SwiftUI.Color(UIColor.systemFill)
    static let background = SwiftUI.Color("BackgroundColor")
    static let secondaryBackground = SwiftUI.Color("SecondaryBackgroundColor")
    static let inputBackground = SwiftUI.Color("InputBackgroundColor")
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
}
