//
//  SuggestionViewModifier.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/28/21.
//

import SwiftUI

/// SuggestionView is a row in a `List` of suggestions.
/// It sets the basic list styles we use for suggestions.
/// Apply it to the "row" view which is an immediate child of `List`.
struct SuggestionViewModifier: ViewModifier {
    var height: CGFloat = 56
    var insets: EdgeInsets = EdgeInsets(
        top: 0,
        leading: AppTheme.tightPadding,
        bottom: 0,
        trailing: AppTheme.tightPadding
    )

    func body(content: Content) -> some View {
        content
            .labelStyle(
                SuggestionLabelStyle(
                    spacing: insets.leading
                )
            )
            .listRowInsets(insets)
            .listRowSeparator(.hidden, edges: .all)
            .frame(height: height)
    }
}
