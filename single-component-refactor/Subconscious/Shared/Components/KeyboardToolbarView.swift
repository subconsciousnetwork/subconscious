//
//  KeyboardToolbarView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct KeyboardToolbarView: View {
    var suggestions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            ScrollView (.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: AppTheme.unit2) {
                    Button(
                        action: {},
                        label: {
                            Image(
                                systemName: "magnifyingglass"
                            ).frame(
                                width: AppTheme.icon,
                                height: AppTheme.icon
                            )
                        }
                    )
                    Divider()
                    ForEach(suggestions, id: \.self) { suggestion in
                        Text(suggestion)
                        Divider()
                    }
                }
                .frame(height: AppTheme.icon, alignment: .center)
                .padding(AppTheme.unit2)
            }
        }
    }
}

struct KeyboardToolbarView_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardToolbarView(
            suggestions: [
                "Floop",
                "The",
                "Pig"
            ]
        )
    }
}
