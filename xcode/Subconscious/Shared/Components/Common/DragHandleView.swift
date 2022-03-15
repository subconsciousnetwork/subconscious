//
//  DragHandleView.swift
//  Subconscious
//
//  Created by Gordon Brander on 3/15/22.
//

import SwiftUI

struct DragHandleView: View {
    var color: Color = Color.secondaryIcon
    var size: CGSize = CGSize(
        width: AppTheme.unit * 10,
        height: AppTheme.unit
    )
    var body: some View {
        Capsule()
            .fill(color)
            .frame(width: size.width, height: size.height)
    }
}

struct DragHandleView_Previews: PreviewProvider {
    static var previews: some View {
        DragHandleView()
    }
}
