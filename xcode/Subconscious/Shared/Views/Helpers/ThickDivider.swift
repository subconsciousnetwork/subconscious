//
//  ThickDivider.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/7/21.
//

import SwiftUI

struct ThickDivider: View {
    var color: Color = Color("Divider")

    var body: some View {
        Rectangle()
           .fill(color)
           .frame(height: 8)
           .edgesIgnoringSafeArea(.horizontal)
    }
}

struct ThickDivider_Previews: PreviewProvider {
    static var previews: some View {
        ThickDivider()
    }
}
