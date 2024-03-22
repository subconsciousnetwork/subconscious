//
//  AudienceIconView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/8/23.
//

import SwiftUI

extension Image {
    init(audience: Audience) {
        switch audience {
        case .public:
            self.init(systemName: "network")
        case .local:
            self.init(systemName: "circle.dashed")
        }
    }
}

extension Label where Title == Text, Icon == Image {
    init<S>(_ title: S, audience: Audience) where S : StringProtocol {
        self.init(
            title: { Text(title) },
            icon: { Image(audience: audience) }
        )
    }
}

struct AudienceIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Image(
                audience: .public
            )
            Image(
                audience: .local
            )
        }
    }
}
