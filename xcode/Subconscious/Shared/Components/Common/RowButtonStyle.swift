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
            configuration.icon
        }
    }
}

/// Underlays a fill on tap when active, much like a UITableView row.
struct RowButtonStyle: ButtonStyle {
    var insets: EdgeInsets = EdgeInsets(
        top: AppTheme.unit2,
        leading: AppTheme.unit4,
        bottom: AppTheme.unit2,
        trailing: AppTheme.unit4
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
        .frame(minHeight: 44)
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
                    Label("Delete", systemImage: "trash")
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
