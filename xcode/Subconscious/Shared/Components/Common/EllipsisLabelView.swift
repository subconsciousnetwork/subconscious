//
//  EllipsisLabelView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 19/7/2023.
//

import Foundation
import SwiftUI

struct EllipsisLabelView: View {
    var body: some View {
        Image(systemName: "ellipsis")
            .frame(width: AppTheme.minTouchSize + AppTheme.padding, height: AppTheme.minTouchSize + AppTheme.unit2)
            .foregroundColor(.secondary)
    }
}
