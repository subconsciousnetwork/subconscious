//
//  CloseButtonView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/3/23.
//

import SwiftUI

/// Circle-X close button used in some sheets.
/// Sight-matched in Figma to close button from Apple Notes.
struct CloseButtonView: View {
    var action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(
            action: action,
            label: {
                Circle()
                    .foregroundStyle(Color.secondaryBackground.opacity(0.7))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    )
                    .blendMode(colorScheme == .light ? .plusDarker : .plusLighter)
                    .frame(
                        width: AppTheme.minTouchSize,
                        height: AppTheme.minTouchSize
                    )
                    .accessibility(label: Text("Close"))
                    .accessibility(hint: Text("Tap to close"))
            }
        )
        .frame(width: 30, height: 30)
    }
}

struct CloseButtonView_Previews: PreviewProvider {
    static var previews: some View {
        CloseButtonView(action: {})
    }
}
