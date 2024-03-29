//
//  TabHeaderView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import SwiftUI

struct TabViewItem {
    var label: String
    var action: () -> Void
}

struct TabHeaderView: View {
    var items: [TabViewItem]
    var tabChanged: (Int, TabViewItem) -> Void
    var focusedTabIndex: Int = 0
    /// Slightly narrow the "selected" bar that appears under the current tab
    var inset = 16.0
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            HStack {
                ForEach(items.indices, id: \.self) { index in
                    let item = items[index]
                    TabButtonView(
                        action: {
                            tabChanged(index, item)
                        },
                        label: item.label,
                        selected: index == focusedTabIndex
                    )
                }
            }
            Spacer()
            GeometryReader { geometry in
                let increment = geometry.size.width * (1.0 / CGFloat(items.count))
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: increment - inset, height: 2)
                    .cornerRadius(2, corners: [.topLeft, .topRight])
                    .offset(x: inset / 2 + increment * CGFloat(focusedTabIndex), y: 0)
                    .animation(.easeInOut(duration: Duration.fast), value: focusedTabIndex)
            }
            .frame(height: 3)
        }
        .frame(maxWidth: .infinity)
    }
}
