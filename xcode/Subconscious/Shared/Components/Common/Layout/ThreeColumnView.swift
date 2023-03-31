//
//  MultiColumnView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import SwiftUI

struct ThreeColumnView<A: View, B: View, C: View>: View {
    var columnA: TabbedColumnItem<A>
    var columnB: TabbedColumnItem<B>
    var columnC: TabbedColumnItem<C>
    
    let focusedColumnIndex: Int

    var body: some View {
        VStack {
            GeometryReader { geometry in
                HStack(alignment: .top, spacing: 0) {
                    ScrollView {
                        columnA.view
                    }
                    .frame(width: geometry.size.width)
                    // Ensures you cannot peek at neighbouring columns in landscape
                    .opacity(focusedColumnIndex == 0 ? 1 : 0)
                    
                    ScrollView {
                        columnB.view
                    }
                    .frame(width: geometry.size.width)
                    .opacity(focusedColumnIndex == 1 ? 1 : 0)
                    
                    ScrollView {
                        columnC.view
                    }
                    .frame(width: geometry.size.width)
                    .opacity(focusedColumnIndex == 2 ? 1 : 0)
                }
                .offset(x: -CGFloat(focusedColumnIndex) * geometry.size.width)
            }
        }
        .background(Color.secondaryBackground)
    }
}
