//
//  ScrimView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/25/22.
//

import SwiftUI

/// A semi-transparent overlay scrim for use in modals
struct ScrimView: View {
    var body: some View {
        Rectangle()
            .foregroundColor(Color.scrim)
    }
}

struct ScrimView_Previews: PreviewProvider {
    static var previews: some View {
        ScrimView()
    }
}
