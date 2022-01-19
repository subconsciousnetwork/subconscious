//
//  MicroFieldButtonStyle.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/19/22.
//

import SwiftUI

/// Underlays a fill on tap when active, much like a UITableView row.
struct MicroFieldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            configuration.label
                .padding(.vertical, AppTheme.unit * 2)
                .padding(.horizontal, AppTheme.unit * 2)
                .frame(maxWidth: .infinity)
                .contentShape(
                    Rectangle()
                )
                .background(Color.secondaryBackground)
                .cornerRadius(AppTheme.cornerRadius)
                .lineLimit(1)
                .font(Font.appCaption)
       }
    }
}
