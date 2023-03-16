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

    var body: some View {
        Button(
            action: action,
            label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 30, height: 30)
                    .foregroundColor(.secondary)
                    .background(Color.secondaryBackground)
                    .clipShape(Circle())
                    .frame(
                        width: Unit.minTouchSize,
                        height: Unit.minTouchSize
                    )
                    .accessibility(label: Text("Close"))
                    .accessibility(hint: Text("Tap to close"))
            }
        )
    }
}

struct CloseButtonView_Previews: PreviewProvider {
    static var previews: some View {
        CloseButtonView(action: {})
    }
}
