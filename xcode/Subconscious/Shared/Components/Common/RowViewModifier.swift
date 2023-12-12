//
//  RowViewModifier.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/14/22.
//
import SwiftUI

struct RowViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content
                .multilineTextAlignment(.leading)
        }
        .listRowInsets(
            EdgeInsets(
                top: AppTheme.unit,
                leading: AppTheme.unit2,
                bottom: AppTheme.unit,
                trailing: AppTheme.unit2
            )
        )
        .listRowSeparator(.hidden, edges: .all)
        .listRowBackground(Color.clear)
    }
}
