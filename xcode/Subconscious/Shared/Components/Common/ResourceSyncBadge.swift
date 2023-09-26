//
//  ResourceSyncBadge.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 30/6/2023.
//

import Foundation
import SwiftUI

struct PendingSyncBadge: View {
    @State var spin = false
    
    var body: some View {
        Image(systemName: "arrow.triangle.2.circlepath")
            .rotationEffect(.degrees(spin ? 360 : 0))
            .animation(Animation.linear
                .repeatForever(autoreverses: false)
                .speed(0.4), value: spin)
            .task{
                self.spin = true
            }
    }
}

struct ResourceSyncBadge: View {
    var status: ResourceStatus

    var body: some View {
        switch status {
        case .initial:
            Image(systemName: "arrow.triangle.2.circlepath")
        case .pending:
            PendingSyncBadge()
        case .succeeded:
            Image(systemName: "checkmark.circle")
        case .failed:
            Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
        }
    }
}
