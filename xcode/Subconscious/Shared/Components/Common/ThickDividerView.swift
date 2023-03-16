//
//  ThickDividerView.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/11/22.
//

import SwiftUI

struct ThickDividerView: View, Equatable {
    var body: some View {
        Color.secondaryBackground
            .frame(height: Unit.two)
    }
}

struct ThickDivider_Previews: PreviewProvider {
    static var previews: some View {
        ThickDividerView()
    }
}
