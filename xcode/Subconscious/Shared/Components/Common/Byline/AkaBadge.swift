//
//  AkaBadge.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 24/5/2023.
//

import SwiftUI

struct AkaBadge: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.secondary)
                .cornerRadius(2, corners: .allCorners)
            Text("AKA")
                .foregroundColor(.background)
                .font(.caption2)
                .bold()
        }
        .frame(
            width: AppTheme.unit * 8,
            height: AppTheme.unit * 4
        )
    }
}

struct AkaBadge_Previews: PreviewProvider {
    static var previews: some View {
        AkaBadge()
    }
}
