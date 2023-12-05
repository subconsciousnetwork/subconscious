//
//  RowViewModifier.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/14/22.
//
import SwiftUI

struct RowViewModifier: ViewModifier {
    var insets = EdgeInsets(
        top: AppTheme.unit3,
        leading: AppTheme.padding,
        bottom: AppTheme.unit3,
        trailing: AppTheme.padding
    )
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content
                .multilineTextAlignment(.leading)
        }
        .listRowInsets(
            EdgeInsets(
                top: 0,
                leading: 0,
                bottom: AppTheme.unit2,
                trailing: 0
            )
        )
        .listRowSeparator(.hidden, edges: .all)
        .listRowBackground(Color.clear)
    }
}
