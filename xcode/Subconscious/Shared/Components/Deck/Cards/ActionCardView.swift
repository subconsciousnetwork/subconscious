//
//  ActionCardView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 27/12/2023.
//

import Foundation
import SwiftUI

struct ActionCardView: View {
    var message: String
    
    var body: some View {
        // TEMP
        VStack {
            Image(systemName: "scribble.variable")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
            Text(message)
        }
        .foregroundStyle(.secondary)
    }
}
