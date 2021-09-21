//
//  KeyboardToolbarView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct KeyboardToolbarView: View {
    var suggestion: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            HStack(alignment: .center, spacing: AppTheme.unit4) {
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
                Button(
                    action: {},
                    label: {
                        Text(suggestion).lineLimit(1)
                    }
                )
                Spacer()
            }
            .frame(height: AppTheme.icon, alignment: .center)
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, AppTheme.tightPadding)
        }
    }
}

struct KeyboardToolbarView_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardToolbarView(
            suggestion: "An organism is a living system maintaining both a higher level of internal cooperation"
        )
    }
}
