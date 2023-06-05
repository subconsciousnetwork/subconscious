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
    var showBar = true
    
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
            .overlay(
                Rectangle()
                    .fill(Color.separator)
                    .frame(height: 1),
                alignment: .bottom
            )
            
            // Position the "selected" bar on top of the buttons
            GeometryReader { geometry in
                let increment = geometry.size.width * (1.0 / CGFloat(items.count))
                if showBar {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: increment - inset, height: geometry.size.height)
                        .cornerRadius(2, corners: [.topLeft, .topRight])
                        .offset(x: inset / 2 + increment * CGFloat(focusedTabIndex), y: 0)
                        .animation(.easeInOut(duration: Duration.fast), value: focusedTabIndex)
                }
            }
            .frame(height: 3) // Vertical height of the bar
        }
        .frame(maxWidth: .infinity)
    }
}
