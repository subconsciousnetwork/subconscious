//
//  FullscreenSheetView.swift
//  Subconscious
//
//  Created by Ben Follington on 27/3/2024.
//

import Foundation
import SwiftUI

struct FullscreenSheetView<ToolbarView: View, ContentView: View>: View {
    var onDismiss: () -> Void
    var toolbar: () -> ToolbarView
    var content: () -> ContentView
    
    @State var dragAmount: CGFloat = 0
    private let dragThreshold: CGFloat = 64
    private let discardThrowDistance: CGFloat = 1024
    private let discardThrowDelay: CGFloat = 0.15
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar()
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        dragAmount = gesture.translation.height
                    }
                    .onEnded { _ in
                        if dragAmount > self.dragThreshold {
                            dragAmount = self.discardThrowDistance
                            DispatchQueue.main.asyncAfter(deadline: .now() + self.discardThrowDelay) {
                                onDismiss()
                            }
                        } else {
                            dragAmount = 0
                        }
                    }
            )
            
            content()
        }
        .cornerRadius(AppTheme.cornerRadiusLg, corners: [.topLeft, .topRight])
        .offset(y: dragAmount)
        .animation(.interactiveSpring(), value: dragAmount)
    }
}
