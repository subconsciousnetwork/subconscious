//
//  AudienceIconView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/8/23.
//

import SwiftUI

struct AudienceIconView: View {
    var audience: Audience

    var body: some View {
        switch audience {
        case .public:
            Image(systemName: "network")
        case .local:
            Image(systemName: "tray.full")
        }
    }
}

struct AudienceIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AudienceIconView(
                audience: .public
            )
            AudienceIconView(
                audience: .local
            )
        }
    }
}
