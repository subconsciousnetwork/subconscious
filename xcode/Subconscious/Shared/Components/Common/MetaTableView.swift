//
//  MetaTableView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/16/23.
//

import SwiftUI

/// A table view box
struct MetaTableView<Rows: View>: View {
    @ViewBuilder var content: () -> Rows

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .cornerRadius(AppTheme.cornerRadiusLg)
        .clipped()
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLg)
                .stroke(Color.separator, lineWidth: 0.5)
        )
    }
}

struct MetaTableLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.icon.frame(
                width: AppTheme.icon,
                height: AppTheme.icon
            )
            Spacer()
            configuration.title
        }
        .padding(RowButtonStyle.insets)
    }
}

struct MetaTableMetadataLabelView: View {
    var title: String
    
    var body: some View {
        Label(title: {
            Text(title)
                .font(.callout.monospaced())
        }, icon: {
            Image(systemName: "key")
        })
        .labelStyle(MetaTableLabelStyle())
        .foregroundColor(.secondary)
    }
}

struct MetaTableItemShareLinkView: View {
    var label: String
    var item: String
    
    var body: some View {
        ShareLink(item: item) {
            Label(
                label,
                systemImage: "square.and.arrow.up"
            )
        }
        .buttonStyle(RowButtonStyle())
    }
}

struct MetaTableItemButtonView: View {
    var label: String
    var systemImage: String
    var action: () -> Void
    var role: ButtonRole? = nil
    
    var body: some View {
        Button(
            role: role,
            action: action
        ) {
            Label(
                label,
                systemImage: systemImage
            )
        }
        .buttonStyle(RowButtonStyle())
    }
}

struct MetaTableRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.accentColor)
            .frame(minHeight: AppTheme.minTouchSize)
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

struct MetaTableRowView: View {
    var icon: Image
    var label: Text
    var text: Text
    var hasDivider = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.unit2) {
                icon
                    .frame(width: AppTheme.icon, height: AppTheme.icon)
                    .foregroundColor(Color.accentColor)
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: AppTheme.unitHalf) {
                            label
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            text
                                .lineLimit(1)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, AppTheme.unit2)
                    if hasDivider {
                        Divider()
                    }
                }
            }
            .padding(.leading, AppTheme.unit2)
        }
        .buttonStyle(MetaTableRowButtonStyle())
    }
}

struct MetaTableView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MetaTableView {
                MetaTableRowView(
                    icon: Image(systemName: "number"),
                    label: Text("Note Revision"),
                    text: Text(verbatim: "Qmf412jQZiuVUtdgnB36FXFasdfasdfasdfasdf")
                ) {
                    
                }
                MetaTableRowView(
                    icon: Image(systemName: "network"),
                    label: Text("Sphere Revision"),
                    text: Text(verbatim: "Qmf412jQZiuVUtdgnB36FXFasdfasdfasdfasdf")
                ) {
                    
                }
                MetaTableRowView(
                    icon: Image(systemName: "key"),
                    label: Text("Author Key"),
                    text: Text(verbatim: "0xb794f5ea0ba39494ce8"),
                    hasDivider: false
                ) {
                    
                }
            }
            VStack {
                MetaTableView {
                    MetaTableRowView(
                        icon: Image(systemName: "number"),
                        label: Text("Note Revision"),
                        text: Text(verbatim: "Qmf412jQZiuVUtdgnB36FXFasdfasdfasdfasdf")
                    ) {
                        
                    }
                    MetaTableRowView(
                        icon: Image(systemName: "network"),
                        label: Text("Sphere Revision"),
                        text: Text(verbatim: "Qmf412jQZiuVUtdgnB36FXFasdfasdfasdfasdf")
                    ) {
                        
                    }
                    MetaTableRowView(
                        icon: Image(systemName: "key"),
                        label: Text("Author Key"),
                        text: Text(verbatim: "0xb794f5ea0ba39494ce8"),
                        hasDivider: false
                    ) {
                        
                    }
                }
            }
            .padding()
            .background(Color.secondaryBackground)

            MetaTableView {
                Button(
                    action: {}
                ) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(RowButtonStyle())
                Divider()
                Button(
                    role: .destructive,
                    action: {}
                ) {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(RowButtonStyle())
            }
        }
    }
}
