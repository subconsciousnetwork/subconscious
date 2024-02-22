//
//  DiscoverActionButtonStyle.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 20/2/2024.
//

import SwiftUI

/// A rounded rectanglular row button style designed for the header
/// This may outgrow its narrow role and the name should be updated if it it used elsewhere
struct DiscoverActionButtonStyle: ButtonStyle {
    private func foregroundColor(_ configuration: Configuration) -> Color {
        configuration.role == .destructive ?
            Color.red :
            Color.accentColor
    }
    
    private var defaultBackgroundColor: Color {
        Color.primaryButtonBackground.opacity(0.5)
    }
    
    private var pressedBackgroundColor: Color {
        Color.primaryButtonBackgroundPressed
    }
    
    private func backgroundColor(_ configuration: Configuration) -> Color {
        configuration.isPressed
            ? pressedBackgroundColor
            : defaultBackgroundColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        .padding(.vertical, AppTheme.unit)
        .padding(.horizontal, AppTheme.unit2)
        .bold()
        .foregroundColor(foregroundColor(configuration))
        .background(backgroundColor(configuration))
        .cornerRadius(AppTheme.cornerRadius)
    }
}
