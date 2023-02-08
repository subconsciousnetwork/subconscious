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
                Section(header: Text("Post Visibility")) {
                    Button(
                        action: {
                            self.audience = .local
                        }
                    ) {
                        Label(
                            title: { Text(Audience.local.description) },
                            icon: { AudienceIconView(audience: .local) }
                        )
                    }
                    Button(
                        action: {
                            self.audience = .public
                        }
                    ) {
                        Label(
                            title: { Text(Audience.public.description) },
                            icon: { AudienceIconView(audience: .public) }
                        )
                    }
                }
            },
            label: {
                VStack(alignment: .leading) {
                    switch audience {
                    case .local:
                        MenuButtonView(
                            icon: AudienceIconView(audience: .local),
                            label: "Local"
                        )
                    case .public:
                        MenuButtonView(
                            icon: AudienceIconView(audience: .public),
                            label: Audience.public.description
                        )
                    }
                }
                // Needed to animate the button transition correctly
                .frame(maxWidth: .infinity, alignment: .leading)
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
