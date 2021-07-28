//
//  PrimaryButtonStyle.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/27/21.
//

import Foundation
import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(Constants.Color.link)
            .padding(.horizontal, 16)
            .frame(height: Constants.Theme.buttonHeight)
            .background(
                configuration.isPressed ?
                Constants.Color.primaryButtonBackground :
                Constants.Color.primaryButtonPressedBackground
            )
            .cornerRadius(CGFloat(Constants.Theme.cornerRadius))
    }
}

struct PrimaryButtonStyle_Preview: PreviewProvider {
    static var previews: some View {
        VStack {
            Button(
                action: {
                    
                },
                label: {
                    Text("Button")
                }
            )
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}
