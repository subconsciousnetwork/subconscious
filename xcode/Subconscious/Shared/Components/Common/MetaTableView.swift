//
//  MetaTableView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/16/23.
//

import SwiftUI

/// A meta table for notes
struct NoteMetaTableView: View {
    var noteCID: String
    var sphereCID: String
    var authorPublicKey: String

    var body: some View {
        VStack(spacing: 0) {
            MetaTableRowView(
                icon: Image(systemName: "number"),
                label: Text("Note Revision"),
                text: Text(verbatim: noteCID)
            )
            MetaTableRowView(
                icon: Image(systemName: "network"),
                label: Text("Sphere Revision"),
                text: Text(verbatim: sphereCID)
            )
            MetaTableRowView(
                icon: Image(systemName: "key"),
                label: Text("Author Key"),
                text: Text(verbatim: authorPublicKey),
                hasDivider: false
            )
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLg)
                .stroke(Color.separator, lineWidth: 0.5)
        )
    }
}

struct MetaTableRowView: View {
    var icon: Image
    var label: Text
    var text: Text
    var hasDivider = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppTheme.unit2) {
                icon
                    .frame(width: AppTheme.icon, height: AppTheme.icon)
                    .foregroundColor(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    label
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    text
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, AppTheme.unit2)
            .padding(.vertical, AppTheme.unit2)
            if hasDivider {
                Divider()
                    .padding(.leading, AppTheme.icon + (AppTheme.unit2 * 2))
            }
        }
    }
}

struct MetaTableView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            NoteMetaTableView(
                noteCID: "Qmf412jQZiuVUtdgnB36FXFasdfasdfasdfasdf",
                sphereCID: "Qmf412jQZiuVUtdgnB36FXFasdfasdfasdfasdf",
                authorPublicKey: "0xb794f5ea0ba39494ce8"
            )
            VStack {
                NoteMetaTableView(
                    noteCID: "Qmf412jQZiuVUtdgnB36FXFasdfasdfasdfasdf",
                    sphereCID: "Qmf412jQZiuVUtdgnB36FXFasdfasdfasdfasdf",
                    authorPublicKey: "0xb794f5ea0ba39494ce8"
                )
            }
            .padding()
            .background(Color.secondaryBackground)
        }
    }
}
