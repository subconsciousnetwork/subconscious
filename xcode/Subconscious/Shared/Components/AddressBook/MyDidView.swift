//
//  MyDidView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 3/3/2023.
//

import Foundation
import SwiftUI

struct MyDidView: View {
    var myDid: Did
    @State var didCopy = false
    
    var body: some View {
        HStack{
            Text(myDid.did)
                .foregroundColor(.secondary)
            Spacer()
            ShareLink(item: myDid.did) {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
}
