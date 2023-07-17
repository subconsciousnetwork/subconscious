//
//  ProfileHeaderButtonStyle.swift
//  Subconscious
//
//  Created by Ben Follington on 17/7/2023.
//

import Foundation
import SwiftUI

/// A rounded rectanglular row button style designed for the header
/// This may outgrow its narrow role and the name should be updated if it it used elsewhere
struct ProfileHeaderButtonStyle: ButtonStyle {
    var variant: ProfileHeaderButtonVariant = .primary
    
    private func foregroundColor(_ configuration: Configuration) -> Color {
        configuration.role == .destructive ?
            Color.red :
            Color.accentColor
    }
    
    private var defaultBackgroundColor: Color {
        variant == .primary
            ? Color.primaryButtonBackground
            : Color.secondaryBackground
    }
    
    private var pressedBackgroundColor: Color {
        variant == .primary
            ? Color.primaryButtonBackgroundPressed
            : Color.backgroundPressed
    }
    
    private func backgroundColor(_ configuration: Configuration) -> Color {
        configuration.isPressed
            ? pressedBackgroundColor
            : defaultBackgroundColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        .bold()
        .foregroundColor(foregroundColor(configuration))
        .frame(maxWidth: .infinity, minHeight: AppTheme.minTouchSize)
        .background(backgroundColor(configuration))
        .cornerRadius(AppTheme.cornerRadius)
    }
}
