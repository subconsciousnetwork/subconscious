//
//  DragHandleView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/22/22.
//

import SwiftUI

struct DragHandleView: View, Equatable {
    var body: some View {
        Capsule()
            .foregroundColor(.tertiaryIcon)
            .frame(
                width: Unit.unit * 12,
                height: Unit.unit
            )
    }
}

struct DragHandleView_Previews: PreviewProvider {
    static var previews: some View {
        DragHandleView()
    }
}
