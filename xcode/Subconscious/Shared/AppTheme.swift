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
}
