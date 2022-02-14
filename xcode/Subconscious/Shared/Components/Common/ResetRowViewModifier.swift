//
//  RowViewModifier.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/14/22.
//
import SwiftUI

struct ResetRowViewModifier: ViewModifier {
    var insets: EdgeInsets? = EdgeInsets(
        top: 0,
        leading: 0,
        bottom: 0,
        trailing: 0
    )
    func body(content: Content) -> some View {
        content
            .listRowInsets(insets)
            .listRowSeparator(.hidden, edges: .all)
    }
}
