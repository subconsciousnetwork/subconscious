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
    static let appText = UIFont(
        name: "IBMPlexSans",
        size: AppTheme.textSize
    )!

    static let appTextMedium = UIFont(
        name: "IBMPlexSans-Medium",
        size: AppTheme.textSize
    )!

    static let appHeadline = UIFont(
        name: "IBMPlexSans-Medium",
        size: 14
    )!

    static let appTextMono = UIFont(
        name: "IBMPlexMono",
        size: AppTheme.textSize
    )!

    static let appTextMonoBold = UIFont(
        name: "IBMPlexMono-Bold",
        size: AppTheme.textSize
    )!

    static let appLargeTitle = UIFont(name: "IBMPlexSans-Light", size: 34)!

    static let appTitle = appTextMedium
    static let appButton = appTextMedium

    static let appCaption = UIFont(
        name: "IBMPlexSans",
        size: AppTheme.captionSize
    )!
}

//  MARK: Fonts
extension Font {
    static let appText = Font(UIFont.appText)
    static let appTextMono = Font(UIFont.appTextMono)
    static let appTextMonoBold = Font(UIFont.appTextMonoBold)
    static let appLargeTitle = Font(UIFont.appLargeTitle)
    static let appTitle = Font(UIFont.appTitle)
    static let appCaption = Font(UIFont.appCaption)
}

//  MARK: Color
//  String color names are references to ColorSet assets, and can be found
//  in Assets.xassets. Each ColorSet contains a light and dark mode, and color
//  is resolved at runtime.
//  2021-12-15 Gordon Brander
extension Color {
    static let text = SwiftUI.Color("TextColor")
    static let textPressed = text.opacity(0.5)
    static let textDisabled = placeholderText
    static let secondaryText = SwiftUI.Color("SecondaryTextColor")
    static let placeholderText = SwiftUI.Color("PlaceholderTextColor")
    static let icon = SwiftUI.Color.accentColor
    static let secondaryIcon = SwiftUI.Color.secondaryText
    static let buttonText = SwiftUI.Color.accentColor
    static let background = SwiftUI.Color("BackgroundColor")
    static let backgroundPressed = SwiftUI.Color(UIColor.systemFill)
    static let secondaryBackground = SwiftUI.Color("SecondaryBackgroundColor")
    static let inputBackground = SwiftUI.Color("InputBackgroundColor")
    static let primaryButtonBackground = SwiftUI.Color(
        "PrimaryButtonBackgroundColor"
    )
    static let primaryButtonBackgroundPressed = primaryButtonBackground
        .opacity(0.5)
    static let primaryButtonBackgroundDisabled = primaryButtonBackground
        .opacity(0.3)
    static let primaryButtonText = SwiftUI.Color("PrimaryButtonTextColor")
    static let primaryButtonTextPressed = fabText.opacity(0.5)
    static let primaryButtonTextDisabled = fabText.opacity(0.3)
    static let fabBackground = primaryButtonBackground
    static let fabBackgroundPressed = primaryButtonBackgroundPressed
    static let fabText = primaryButtonText
    static let fabTextPressed = primaryButtonTextPressed
    static let fabTextDisabled = primaryButtonTextDisabled
    static let scrim = SwiftUI.Color(UIColor.tertiarySystemFill)
}
