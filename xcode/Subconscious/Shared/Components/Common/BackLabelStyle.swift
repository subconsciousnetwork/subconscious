//
//  BackLabelStyle.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/12/22.
//

import SwiftUI

/// Label style for custom back button with text
struct BackLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Unit.unit) {
            configuration.icon
                .frame(height: Unit.icon)
            configuration.title
                .lineLimit(1)
        }
    }
}
