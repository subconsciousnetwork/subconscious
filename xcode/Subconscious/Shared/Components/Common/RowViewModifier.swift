//
//  RowViewModifier.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/14/22.
//
import SwiftUI

struct RowViewModifier: ViewModifier {
    var insets = EdgeInsets(
        top: Unit.three,
        leading: Unit.padding,
        bottom: Unit.three,
        trailing: Unit.padding
    )
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content
                .multilineTextAlignment(.leading)
                .padding(insets)
            Divider()
                .padding(.leading, insets.leading)
        }
        .listRowInsets(
            EdgeInsets(
                top: 0,
                leading: 0,
                bottom: 0,
                trailing: 0
            )
        )
        .listRowSeparator(.hidden, edges: .all)
    }
}
