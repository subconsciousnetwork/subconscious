//
//  CountChip.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/25/22.
//

import SwiftUI

struct CountChip: View, Equatable {
    var count: Int?

    private static func asText(count: Int?) -> String {
        guard let count = count else {
            return "⋯"
        }
        guard count < 10000 else {
            return "∞"
        }
        return count.description
    }

    var body: some View {
        Text(Self.asText(count: count))
            .font(Font(UIFont.appCaption))
            .padding(.horizontal, AppTheme.unit2)
            .padding(.vertical, AppTheme.unit)
            .background(Color.secondaryBackground)
            .foregroundColor(Color.secondaryText)
            .clipShape(Capsule())
    }
}

struct CountChip_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CountChip(
                count: 100
            )
            CountChip(
                count: 10000000000
            )
            CountChip(
                count: 0
            )
            CountChip(
                count: nil
            )
        }
    }
}
