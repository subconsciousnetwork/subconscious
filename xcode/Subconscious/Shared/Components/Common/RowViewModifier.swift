//
//  RowViewModifier.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/14/22.
//
import SwiftUI

struct RowViewModifier: ViewModifier {
    var insets: EdgeInsets? = EdgeInsets(
        top: 0,
        leading: 0,
        bottom: 0,
        trailing: 0
    )
    func body(content: Content) -> some View {
        content
            .labelStyle(RowLabelStyle())
            .listRowInsets(insets)
            .listRowSeparator(.hidden, edges: .all)
    }
}
