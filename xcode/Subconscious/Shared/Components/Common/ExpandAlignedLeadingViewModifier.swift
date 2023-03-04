//
//  ExpandHorizontal.swift
//  Subconscious
//
//  Created by Gordon Brander on 3/4/23.
//

import SwiftUI

/// Modify a view so that it expands to fill the whole available
/// horizontal space, with content aligned leading.
struct ExpandAlignLeadingViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        HStack(spacing: 0) {
            content
            Spacer()
        }
    }
}

extension View {
    /// Modify a view so that it expands to fill the whole available
    /// horizontal space, with content aligned leading.
    func expandAlignedLeading() -> some View {
        self.modifier(ExpandAlignLeadingViewModifier())
    }
}


struct CellViewModifier_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Hello")
                .expandAlignedLeading()
                .background(.yellow)
        }
    }
}
