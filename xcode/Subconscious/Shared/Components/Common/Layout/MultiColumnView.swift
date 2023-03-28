//
//  MultiColumnView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import SwiftUI

struct MultiColumnView: View {
    var user: User
    let focusedColumnIndex: Int
    let columns: [AnyView]

    var body: some View {
        VStack {
            GeometryReader { geometry in
                HStack(alignment: .top, spacing: 0) {
                    ForEach(columns.indices, id: \.self) { index in
                        let column = columns[index]
                        ScrollableColumnView(width: geometry.size.width) {
                            column
                        }
                        // Ensures you cannot peek at neighbouring columns in landscape
                        .opacity(index == focusedColumnIndex ? 1 : 0)
                    }
                }
                .offset(x: -CGFloat(focusedColumnIndex) * geometry.size.width)
            }
        }
    }
}
