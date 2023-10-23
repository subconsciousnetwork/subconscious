//
//  FeedPlaceholderView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 13/10/2023.
//

import SwiftUI

struct FeedPlaceholderView: View {
    var body: some View {
        VStack {
            StoryPlaceholderView(bioWidthFactor: 1.2)
            StoryPlaceholderView(delay: 0.25, nameWidthFactor: 0.7, bioWidthFactor: 0.9)
            StoryPlaceholderView(delay: 0.5, nameWidthFactor: 0.7, bioWidthFactor: 0.5)
            
            Spacer()
        }
    }
}
