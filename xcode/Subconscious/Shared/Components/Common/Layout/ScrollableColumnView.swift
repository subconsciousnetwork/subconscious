//
//  ScrollableColumnView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import SwiftUI

struct ScrollableColumnView<Content: View>: View {
    var width: CGFloat
    var content: Content
    
    init(width: CGFloat, content: () -> Content) {
        self.width = width
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            VStack {
                Spacer(minLength: AppTheme.padding)
                content
            }
            .padding(
                EdgeInsets(
                    top: 0,
                    leading: AppTheme.padding,
                    bottom: 0,
                    trailing: AppTheme.padding
                )
            )
        }
        .frame(width: width)
    }
}
