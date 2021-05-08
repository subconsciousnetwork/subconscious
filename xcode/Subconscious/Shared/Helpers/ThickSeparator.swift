//
//  ThickDivider.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/7/21.
//

import SwiftUI

struct ThickSeparator: View {
    var color: Color = .Subconscious.thickSeparator

    var body: some View {
        Rectangle()
           .fill(color)
           .frame(height: 8)
           .edgesIgnoringSafeArea(.horizontal)
    }
}

struct ThickDivider_Previews: PreviewProvider {
    static var previews: some View {
        ThickSeparator()
    }
}
