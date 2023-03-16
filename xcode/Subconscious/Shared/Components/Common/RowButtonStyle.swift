//
//  RowButtonStyle.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/16/21.
//

import SwiftUI

struct RowLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            Spacer()
            configuration.icon.frame(
                width: Unit.icon,
                height: Unit.icon
            )
        }
    }
}

/// Underlays a fill on tap when active, much like a UITableView row.
struct RowButtonStyle: ButtonStyle {
    var insets: EdgeInsets = EdgeInsets(
        top: Unit.two,
        leading: Unit.four,
        bottom: Unit.two,
        trailing: Unit.four
    )

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .labelStyle(RowLabelStyle())
                .foregroundColor(
                    configuration.role == .destructive ?
                    Color.red :
                    Color.primaryButtonText
                )
        }
        .padding(insets)
        .frame(minHeight: Unit.minTouchSize)
        .contentShape(
            Rectangle()
        )
        .overlay {
            Rectangle()
                .foregroundColor(
                    configuration.isPressed ?
                    Color.backgroundPressed :
                    Color.clear
                )
        }
    }
}

struct RowButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Button(
                action: {}
            ) {
                Label(
                    "Move",
                    systemImage: "rectangle.portrait.and.arrow.right"
                )
            }
            .buttonStyle(RowButtonStyle())

            Button(
                role: .destructive,
                action: {},
                label: {
                    Label("Delete", systemImage: "trash")
                }
            )
            .buttonStyle(RowButtonStyle())

            Button(
                action: {},
                label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            )
            .buttonStyle(RowButtonStyle())

            Button(
                role: .destructive,
                action: {},
                label: {
                    Text("Delete")
                        .expandAlignedLeading()
                }
            )
            .buttonStyle(RowButtonStyle())

            Button(
                role: .destructive,
                action: {},
                label: {
                    Text("Delete")
                }
            )
            .buttonStyle(RowButtonStyle())

            Label("Trash", systemImage: "trash")
                .labelStyle(RowLabelStyle())
        }
    }
}
