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
            Button(action: {
                // TODO: actually copy it!
                didCopy = true
            }, label: {
                if !didCopy {
                    HStack {
                        Image(systemName: "doc.on.doc")
                    }
                    .transition(
                        .asymmetric(
                            insertion: .identity,
                            removal: .move(
                                edge: .top
                            ).combined(
                                with: .opacity
                            )
                        )
                    )
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle")
                    }
                    .transition(.opacity)
                }
            })
        }
    }
}
