//
//  FabSpacerView.swift
//  Subconscious
//
//  Created by Ben Follington on 10/7/2023.
//

import Foundation
import SwiftUI

/// Introduce space at the bottom of a scrollable view to
/// void overlapping the FAB.
struct FabSpacerView: View {
    var body: some View {
        // Add space at the bottom of the list so that FAB
        // does not cover up swipe actions of last item.
        Color.clear
            .frame(
                height: (
                    AppTheme.fabSize +
                    (AppTheme.unit * 6)
                )
            )
            .listRowSeparator(.hidden)
    }
}
