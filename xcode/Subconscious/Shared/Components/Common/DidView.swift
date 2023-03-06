//
//  DidView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 3/3/2023.
//

import Foundation
import SwiftUI

struct DidView: View {
    var did: Did
    
    var body: some View {
        HStack{
            Text(did.did)
                .foregroundColor(.secondary)
            Spacer()
            ShareLink(item: did.did) {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
}
