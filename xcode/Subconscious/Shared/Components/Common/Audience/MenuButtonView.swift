//
//  MenuButtonView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/8/23.
//

import SwiftUI

/// Generic menu pill button view
struct MenuButtonView<Icon: View>: View {
    @ScaledMetric(relativeTo: .caption)
    private var height: CGFloat = 30

    @ScaledMetric(relativeTo: .caption)
    private var iconSize: CGFloat = 12
    
    var icon: Icon
    var label: String

    var body: some View {
        HStack(spacing: AppTheme.unit) {
            icon
                .font(.system(size: iconSize))
            Text(label)
                .bold()
                .font(.caption)
            Spacer()
            Image(systemName: "chevron.down")
                .font(.system(size: iconSize))
                .foregroundColor(Color.secondary)
        }
        .foregroundColor(Color.accentColor)
        .lineLimit(1)
        .frame(height: height)
        .padding(
            .horizontal, AppTheme.unit2
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(Color.separator, lineWidth: 0.5)
        )
    }
}

struct MenuButtonView_Previews: PreviewProvider {
    static var previews: some View {
        MenuButtonView(
            icon: Image(systemName: "network"),
            label: "Everyone"
        )
    }
}
