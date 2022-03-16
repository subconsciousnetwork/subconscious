//
//  PinTrailingBottom.swift
//  Subconscious
//
//  Created by Gordon Brander on 3/16/22.
//

import SwiftUI

/// Pins some other view to the bottom right (trailing edge)
/// of the screen.
struct PinTrailingBottom<Content>: View
where Content: View
{
    var content: Content
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                content
            }
        }
    }
}

struct PinTrailingBottom_Previews: PreviewProvider {
    static var previews: some View {
        PinTrailingBottom(
            content: Circle()
                .frame(width: 64, height: 64)
                .foregroundColor(Color.black)
        )
    }
}
