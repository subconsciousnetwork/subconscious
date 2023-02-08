//
//  MenuButtonView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/8/23.
//

import SwiftUI

/// Generic menu pill button view
struct MenuButtonView<Icon: View>: View {
    var icon: Icon
    var label: String

    var body: some View {
        HStack(spacing: AppTheme.unit) {
            icon
                .font(.system(size: 12))
            Text(label)
                .bold()
                .font(.caption)
            Image(systemName: "chevron.down")
                .font(.system(size: 12))
        }
        .lineLimit(1)
        .frame(height: AppTheme.unit * 6)
        .foregroundColor(Color.primaryButtonText)
        .padding(
            .horizontal, AppTheme.unit * 3
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.accentColor, lineWidth: 1)
        )
    }
}

struct MenuButtonView_Previews: PreviewProvider {
    static var previews: some View {
        MenuButtonView(
            icon: Image(systemName: "network"),
            label: "Public"
        )
    }
}
