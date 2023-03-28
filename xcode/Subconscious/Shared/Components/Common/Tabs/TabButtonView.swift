//
//  TabButtonView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import SwiftUI

struct TabButtonView<Label: View>: View {
    var action: () -> Void
    let label: Label
    var selected: Bool

    init(@ViewBuilder label: () -> Label) {
        self.label = label()
        self.selected = false
        self.action = {}
    }
    
    init(@ViewBuilder label: () -> Label, action: @escaping () -> Void, selected: Bool) {
        self.label = label()
        self.action = action
        self.selected = selected
    }
    
    var body: some View {
        Button(
            action: action,
            label: {
                label
                    .font(.callout)
                    .bold(selected)
            }
        )
        .foregroundColor(selected ? Color.accentColor : Color.secondary )
        .frame(maxWidth: .infinity)
        .padding()
    }
}
