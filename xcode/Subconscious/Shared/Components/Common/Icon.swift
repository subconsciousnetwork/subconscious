//
//  Icon.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/20/21.
//

import SwiftUI

/// Provides a frameable box for icons with a default size of 24x24
struct IconView: View {
    var image: Image
    var width: CGFloat = 24
    var height: CGFloat = 24

    var body: some View {
        image
            .frame(width: width, height: height)
            .scaledToFit()
    }
}

struct IconView_Previews: PreviewProvider {
    static var previews: some View {
        IconView(image: Image(systemName: "chevron.left"))
    }
}
