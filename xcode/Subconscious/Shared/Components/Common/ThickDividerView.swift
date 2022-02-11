//
//  ThickDividerView.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/11/22.
//

import SwiftUI

struct ThickDividerView: View {
    var body: some View {
        Color.secondaryBackground
            .frame(height: AppTheme.unit2)
    }
}

struct ThickDivider_Previews: PreviewProvider {
    static var previews: some View {
        ThickDividerView()
    }
}
