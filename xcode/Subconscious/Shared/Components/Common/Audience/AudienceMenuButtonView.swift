//
//  AudienceMenuButton.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/15/21.
//

import SwiftUI

struct AudienceMenuButtonView: View {
    @Binding var audience: Audience

    var body: some View {
        Menu(
            content: {
                Section(header: Text("Note Audience")) {
                    Button(
                        action: {
                            self.audience = .local
                        }
                    ) {
                        Label(
                            title: { Text(Audience.local.description) },
                            icon: { Image(audience: .local) }
                        )
                    }
                    Button(
                        action: {
                            self.audience = .public
                        }
                    ) {
                        Label(
                            title: { Text(Audience.public.description) },
                            icon: { Image(audience: .public) }
                        )
                    }
                }
            },
            label: {
                MenuButtonView(
                    icon: Image(audience: audience),
                    label: audience.description
                )
                .frame(width: 140)
            }
        )
    }
}

struct AudienceSelectorButtonStyle_Previews: PreviewProvider {
    struct TestAudienceView: View {
        @State var audience: Audience = .local
        var body: some View {
            AudienceMenuButtonView(
                audience: $audience
            )
        }
    }

    static var previews: some View {
        VStack(alignment: .leading) {
            TestAudienceView()
        }
    }
}
