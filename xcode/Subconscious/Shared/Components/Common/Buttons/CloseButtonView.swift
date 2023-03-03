//
//  CloseButtonView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/3/23.
//

import SwiftUI

/// Circle-X close button used in some sheets
struct CloseButtonView: View {
    var action: () -> Void

    var body: some View {
        Button(
            action: action,
            label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 24, height: 24)
                    .foregroundColor(.secondary)
                    .background(Color.secondaryBackground)
                    .clipShape(Circle())
                    .frame(width: 32, height: 32)
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
