//
//  TabbedColumnView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import SwiftUI

struct TabbedColumnItem {
    var label: String
    var view: any View
}

struct TabbedColumnView: View {
    var columns: [TabbedColumnItem]
    var selectedColumnIndex: Int = 0
    var changeColumn: (Int) -> Void
    
    var body: some View {
        TabHeaderView(
            items: columns.enumerated().map { (index, column) in
                TabViewItem(
                    label: column.label,
                    action: { changeColumn(index) }
                )
            },
            tabChanged: { index, tab in changeColumn(index) },
            focusedTabIndex: selectedColumnIndex
        )
        
        MultiColumnView(
            focusedColumnIndex: selectedColumnIndex,
            columns: columns.map { column in
                AnyView(column.view)
            }
        )
    }
}
