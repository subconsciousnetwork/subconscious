//
//  RowLabelStyle.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/14/22.
//

import SwiftUI

/// A Label style that is like the standard row style with dividers
/// but giving us more control over how they appear.
/// Creates label style analogous to a default list label
/// However, this version gives us more control over the styling, allowing us to create hanging icons.
struct RowLabelStyle: LabelStyle {
    var iconColor = Color.secondaryIcon
    var insets = EdgeInsets(
        top: AppTheme.unit3,
        leading: AppTheme.tightPadding,
        bottom: AppTheme.unit3,
        trailing: AppTheme.tightPadding
    )
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: insets.leading) {
            configuration.icon
                .frame(
                    width: AppTheme.icon,
                    height: AppTheme.icon
                )
                .foregroundColor(iconColor)
            VStack(spacing: insets.bottom) {
                configuration.title
                    .foregroundColor(Color.text)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                    .padding(.trailing, insets.trailing)
                Divider()
            }
        }
        .padding(.leading, insets.leading)
        .padding(.top, insets.top)
    }
}
