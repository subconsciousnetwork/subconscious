//
//  ListHeader.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/13/21.
//

import SwiftUI

/// A custom list header, roughly in the style of the list header style used for `List`
struct ListHeader<Subview: View>: View {
    let title: Subview
    
    var body: some View {
        HStack {
            title.font(.headline)
            Spacer()

        }
        .padding(.vertical, 4)
        .padding(.horizontal, 16)
        .background(Color.Sub.secondaryBackground)
    }
}

struct ListHeader_Previews: PreviewProvider {
    static var previews: some View {
        ListHeader(
            title: Text("Title")
        )
    }
}
