//
//  TabButtonView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import SwiftUI

struct TabButtonView: View {
    var action: () -> Void
    var label: String
    var selected: Bool
    
    var body: some View {
        Button(
            action: action,
            label: {
                Text(label)
                    .font(.callout)
                    .bold(selected)
            }
        )
        .foregroundColor(selected ? Color.accentColor : Color.secondary )
        .frame(maxWidth: .infinity)
        .padding()
    }
}
