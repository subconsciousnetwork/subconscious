//
//  FullButtonStyle.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/27/21.
//

import Foundation
import SwiftUI

/// A full-width button for major actions.
struct FullButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .lineLimit(1)
            .foregroundColor(Constants.Color.link)
            .padding(.horizontal, 16)
            .frame(
                maxWidth: .infinity,
                minHeight: Constants.Theme.buttonHeight,
                idealHeight: Constants.Theme.buttonHeight,
                maxHeight: Constants.Theme.buttonHeight,
                alignment: .center
            )
            .background(
                configuration.isPressed ?
                Constants.Color.primaryButtonBackground :
                Constants.Color.primaryButtonPressedBackground
            )
            .cornerRadius(CGFloat(Constants.Theme.cornerRadius))
            .shadow(color: .black.opacity(0.2), radius: 0, x: 0, y: 1)
    }
}

struct FullButtonStyle_Preview: PreviewProvider {
    static var previews: some View {
        VStack {
            Button(
                action: {
                    
                },
                label: {
                    Text("Button lorem ipsum dolor sit amet consectetur adipisicing elit")
                }
            )
            .buttonStyle(FullButtonStyle())
        }
    }
}
