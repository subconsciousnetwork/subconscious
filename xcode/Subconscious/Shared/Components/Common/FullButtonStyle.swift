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
    }
}

struct FullButtonStyle_Preview: PreviewProvider {
    static var previews: some View {
        VStack {
            Button(
                action: {
                    
                },
                label: {
                    Text("Button")
                }
            )
            .buttonStyle(FullButtonStyle())
        }
    }
}
