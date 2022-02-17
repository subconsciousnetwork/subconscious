//
//  RowButtonStyle.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/16/21.
//

import SwiftUI

/// Underlays a fill on tap when active, much like a UITableView row.
struct RowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Rectangle()
                .foregroundColor(
                    configuration.isPressed ?
                    Color.pressedFill :
                    Color.clear
                )
            configuration.label
                .contentShape(
                    Rectangle()
                )
        }
    }
}
