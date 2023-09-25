//
//  ErrorDetailView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 25/9/2023.
//

import Foundation
import SwiftUI

struct ErrorDetailView: View {
    var error: String
    
    var body: some View {
        ScrollView {
            Text(error)
                .font(.caption.monospaced())
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
        }
        .frame(idealHeight: 24, maxHeight: 128)
        .expandAlignedLeading()
        .padding(AppTheme.tightPadding)
        .foregroundColor(.secondary)
        .background(Color.secondaryBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
}
