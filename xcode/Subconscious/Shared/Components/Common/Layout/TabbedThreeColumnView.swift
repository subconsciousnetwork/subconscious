//
//  TabbedThreeColumnView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import SwiftUI

struct TabbedColumnItem<Content: View> {
    var label: String
    var view: Content
}

struct TabbedThreeColumnView<A: View, B: View, C: View>: View {
    var columnA: TabbedColumnItem<A>
    var columnB: TabbedColumnItem<B>
    var columnC: TabbedColumnItem<C>
    
    var selectedColumnIndex: Int = 0
    var changeColumn: (Int) -> Void
    var showBar: Bool = true
    
    var body: some View {
        TabHeaderView(
            items: [
                TabViewItem(
                    label: columnA.label,
                    action: { changeColumn(0) }
                ),
                TabViewItem(
                    label: columnB.label,
                    action: { changeColumn(1) }
                ),
                TabViewItem(
                    label: columnC.label,
                    action: { changeColumn(2) }
                )
            ],
            tabChanged: { index, tab in changeColumn(index) },
            focusedTabIndex: selectedColumnIndex,
            showBar: showBar
        )
        
        ThreeColumnView(
            columnA: columnA,
            columnB: columnB,
            columnC: columnC,
            focusedColumnIndex: selectedColumnIndex
        )
    }
}
