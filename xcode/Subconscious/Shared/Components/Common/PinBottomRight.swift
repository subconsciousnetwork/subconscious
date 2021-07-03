//
//  FloatingActionButton.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/13/21.
//

import SwiftUI

struct PinBottomRight<InnerView: View>: View {
    let view: () -> InnerView
    
    var body: some View {
        VStack(alignment: .trailing) {
            Spacer()
            HStack {
                Spacer()
                HStack {
                    view()
                }
            }
        }
    }
}

struct PinBottomRight_Previews: PreviewProvider {
    static var previews: some View {
        PinBottomRight {
            ActionButton()
        }
        .padding(16)
    }
}
