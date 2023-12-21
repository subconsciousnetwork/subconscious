//
//  PaletteButtonStyle.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 12/21/23.
//

import SwiftUI

struct PaletteButtonStyle: ButtonStyle {
    var size: CGFloat = 72

    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.label
                .labelStyle(PaletteLabelStyle())
        }
        .frame(
            width: size,
            height: size
        )
        .background(Color.secondaryBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
}

struct PaletteLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.icon
                .frame(width: AppTheme.icon, height: AppTheme.icon)
                .padding(.bottom, AppTheme.unitHalf)
            configuration.title
                .font(.caption)
        }
        .padding(AppTheme.unit2)
    }
}

struct PaletteButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button(
            action: {},
            label: {
                Label(
                    title: { Text("Label") },
                    icon: { Image(systemName: "doc.on.doc") }
                )
            }
        )
        .buttonStyle(PaletteButtonStyle())
    }
}
