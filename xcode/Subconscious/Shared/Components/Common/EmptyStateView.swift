//
//  EmptyState.swift
//  Subconscious
//
//  Created by Ben Follington on 11/5/2023.
//

import Foundation
import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: AppTheme.unit * 6) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 64))
            Text("Nothing to see here... yet!")
            Spacer()
        }
        .padding(AppTheme.padding)
        .font(.caption)
        .foregroundColor(Color.secondary)
        .background(Color.clear)
        .transition(.opacity)
        .frame(maxWidth: .infinity)
    }
}
