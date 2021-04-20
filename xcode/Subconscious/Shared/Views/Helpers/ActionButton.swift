//
//  ActionButton.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/13/21.
//

import SwiftUI

// A FAB. Just the disk, no positioning.
struct ActionButton: View {
    var backgroundColor = Color.black
    var foregroundColor = Color.white
    var size: CGFloat = 56
    var icon = "plus"
    var iconSize: CGFloat = 16
    var iconWeight = Font.Weight.bold

    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(backgroundColor)
                .frame(width: size, height: size)
                .shadow(radius: 8, x: 0, y: 2)
            Image(systemName: icon)
                .font(
                    Font
                        .system(size: iconSize)
                        .weight(iconWeight)
                )
                .foregroundColor(foregroundColor)
        }
    }
}

struct ActionButton_Previews: PreviewProvider {
    static var previews: some View {
        ActionButton()
    }
}
