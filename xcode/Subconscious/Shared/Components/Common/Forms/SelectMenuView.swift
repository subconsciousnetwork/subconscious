//
//  SelectMenuView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/3/23.
//

import SwiftUI

struct SelectMenuView<Label: View, Content: View>: View {
    @ViewBuilder var content: () -> Content
    var label: () -> Label

    var body: some View {
        Menu(
            content: content,
            label: {
                HStack {
                    label()
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 8)
                .padding(.trailing, 12)
                .frame(height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(Color.separator, lineWidth: 0.5)
                )
            }
        )
    }
}

struct SelectMenuView_Previews: PreviewProvider {
    static var previews: some View {
        SelectMenuView(
            content: {
                Button(
                    action: {
                    }
                ) {
                    Label(
                        title: { Text(Audience.local.description) },
                        icon: { Image(audience: .local) }
                    )
                }
                Button(
                    action: {
                    }
                ) {
                    Label(
                        title: { Text(Audience.public.description) },
                        icon: { Image(audience: .public) }
                    )
                }
            },
            label: { Text("Everyone") }
        )
    }
}
