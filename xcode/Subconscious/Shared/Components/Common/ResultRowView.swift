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
struct ResultRowView: View {
    static let height: CGFloat = 56
    var action: () -> Void
    var icon: Image
    var title: Text
    var subtitle: Text

    var body: some View {
        // We embed button _within_ view, because list style
        // decorators must be at the top-level to have effect on list.
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
                            HStack {
                                subtitle
                                    .font(Font(UIFont.appCaption))
                                    .foregroundColor(Color.secondaryText)
                                Spacer()
                            }
                            .frame(minHeight: AppTheme.captionSize)
                        }
                    },
                    icon: { icon }
                )
            }
        )
        .labelStyle(
            ResultRowLabelStyle(spacing: AppTheme.tightPadding)
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
    }
}

/// Creates label style analogous to a default list label
/// However, this version gives us more control over the styling, allowing us to create hanging icons.
struct ResultRowLabelStyle: LabelStyle {
    var spacing: CGFloat? = nil
    var iconColor = Color.icon

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: spacing) {
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

struct SuggestionRowView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ResultRowView(
                action: {},
                icon: Image(systemName: "doc"),
                title: Text("Aurora, rosy daughter of the dawn, Now ting’d the East, when habited again"),
                subtitle: Text("Uprose Ulysses’ offspring from his bed. Athwart his back his faulchion keen he flung, His sandals bound to his unsullied feet, And, godlike, issued from his chamber-door.")
            )
            ResultRowView(
                action: {},
                icon: Image(systemName: "doc"),
                title: Text("To roam all night the Ocean’s dreary waste"),
                subtitle: Text("But winds to ships injurious spring by night.")
            )
            ResultRowView(
                action: {},
                icon: Image(systemName: "doc"),
                title: Text("Prepare we rather now, as night enjoins"),
                subtitle: Text("Our evening fare beside the sable bark.")
            )
        }
        .listStyle(.plain)
    }
}
