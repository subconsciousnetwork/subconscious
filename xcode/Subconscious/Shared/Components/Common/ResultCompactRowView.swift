//
//  ResultRowView.swift
//  Subconscious
//
//  Created by Gordon Brander on 6/12/22.
//

import SwiftUI

/// A generic result row with an icon, title and subtitle
/// This row has a static fixed height, so you can calculate the
/// size it takes up in the layout.
struct ResultCompactRowView: View {
    static let height: CGFloat = AppTheme.minHitTarget
    var action: () -> Void
    var icon: Image
    var title: Text

    var body: some View {
        Button(
            action: action,
            label: {
                Label(
                    title: {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                title
                                    .font(Font(UIFont.appText))
                                    .foregroundColor(Color.text)
                                Spacer()
                            }
                            .frame(minHeight: AppTheme.icon)
                        }
                    },
                    icon: { icon }
                )
            }
        )
        .labelStyle(
            ResultCompactRowLabelStyle()
        )
        .listRowInsets(
            EdgeInsets(
                top: 0,
                leading: AppTheme.tightPadding,
                bottom: 0,
                trailing: AppTheme.tightPadding
            )
        )
        .listRowSeparator(.hidden, edges: .all)
        .frame(height: Self.height)
        .background(.blue)
    }
}

/// Creates label style analogous to a default list label
/// However, this version gives us more control over the styling, allowing us to create hanging icons.
struct ResultCompactRowLabelStyle: LabelStyle {
    var spacing: CGFloat = AppTheme.tightPadding
    var iconColor = Color.icon

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: AppTheme.tightPadding) {
            configuration.icon
                .frame(
                    width: AppTheme.icon,
                    height: AppTheme.icon
                )
                .foregroundColor(iconColor)
            configuration.title
                .foregroundColor(Color.text)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
        }
    }
}

struct ResultCompactRowView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ResultCompactRowView(
                action: {},
                icon: Image(systemName: "doc"),
                title: Text("Aurora, rosy daughter of the dawn, Now ting’d the East, when habited again")
            )
            ResultCompactRowView(
                action: {},
                icon: Image(systemName: "doc"),
                title: Text("To roam all night the Ocean’s dreary waste")
            )
            ResultCompactRowView(
                action: {},
                icon: Image(systemName: "doc"),
                title: Text("Prepare we rather now, as night enjoins")
            )
        }
        .listStyle(.plain)
    }
}
