//
//  StoryPlaceholderView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 6/6/2023.
//

import SwiftUI

struct FeedPlaceholderView: View {
    var body: some View {
        StoryPlaceholderView(bioWidthFactor: 1.2)
        StoryPlaceholderView(delay: 0.25, nameWidthFactor: 0.7, bioWidthFactor: 0.9)
        StoryPlaceholderView(delay: 0.5, nameWidthFactor: 0.7, bioWidthFactor: 0.5)
    }
}

/// Show a placeholder story designed for a loading state
struct StoryPlaceholderView: View {
    @State var opacity = 1.0
    var delay = 0.0
    var nameWidthFactor = 1.0
    var bioWidthFactor = 1.0
    
    private static let color = Color.separator.opacity(0.5)
    
    var body: some View {
        Button(
            action: { },
            label: {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center, spacing: AppTheme.unit) {
                        Circle()
                            .foregroundColor(Self.color)
                            .frame(maxHeight: 24)
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .foregroundColor(Self.color)
                            .frame(maxWidth: 128 * nameWidthFactor, maxHeight: 14)
                        
                        Spacer()
                        
                    }
                    .padding(AppTheme.tightPadding)
                    .frame(height: AppTheme.unit * 12)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: AppTheme.unit2) {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .foregroundColor(Self.color)
                            .frame(maxHeight: 14)
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .foregroundColor(Self.color)
                            .frame(maxWidth: 200 * bioWidthFactor, maxHeight: 14)
                    }
                    .padding(AppTheme.tightPadding)
                }
                .background(Color.background)
                .contentShape(Rectangle())
            }
        )
        .buttonStyle(.plain)
        .opacity(opacity)
        .animation(
            .easeInOut(duration: Duration.loading)
                .repeatForever(autoreverses: true)
                .delay(delay),
            value: opacity
        )
        .onAppear {
            opacity = 0.33
        }
    }
}

struct StoryPlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        StoryPlaceholderView()
    }
}
