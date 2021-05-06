//
//  Icon.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/20/21.
//

import SwiftUI

/// Provides a frameable box for icons with a default size of 24x24
struct Icon: View {
    var image: Image
    var width: CGFloat = 24
    var height: CGFloat = 24

    var body: some View {
        HStack {
            image
        }
        .frame(width: width, height: height)
    }
}

struct Icon_Previews: PreviewProvider {
    static var previews: some View {
        Icon(image: Image(systemName: "chevron.left"))
    }
}
