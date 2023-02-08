//
//  AudienceMenuButton.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/15/21.
//

import SwiftUI

struct AudienceIcon: View {
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

struct AudienceMenuButton: View {
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
                            icon: { AudienceIcon(audience: .local) }
                        )
                    }
                    Button(
                        action: {
                            self.audience = .public
                        }
                    ) {
                        Label(
                            title: { Text(Audience.public.description) },
                            icon: { AudienceIcon(audience: .public) }
                        )
                    }
                }
            },
            label: {
                HStack(spacing: AppTheme.unit) {
                    AudienceIcon(audience: audience)
                        .font(.system(size: 12))
                    Text(verbatim: audience.description)
                        .bold()
                        .font(.caption)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                }
                .frame(height: AppTheme.unit * 6)
                .foregroundColor(Color.primaryButtonText)
                .padding(
                    .horizontal, AppTheme.unit * 3
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.accentColor, lineWidth: 1)
                )
            }
        )
    }
}

struct AudienceSelectorButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: AppTheme.unit) {
            configuration.label
                .bold()
                .font(.caption)
            Image(systemName: "chevron.down")
                .font(.system(size: 12))
        }
        .frame(height: AppTheme.unit * 6)
        .foregroundColor(
            Color.chooseForState(
                isPressed: configuration.isPressed,
                isEnabled: isEnabled,
                normal: Color.primaryButtonText,
                pressed: Color.primaryButtonTextPressed,
                disabled: Color.primaryButtonTextDisabled
            )
        )
        .padding(
            .horizontal, AppTheme.unit * 4
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.accentColor, lineWidth: 1)
        )
        .animation(.default, value: configuration.isPressed)
    }
}

struct AudienceSelectorButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        AudienceMenuButton(
            audience: .constant(.local)
        )
    }
}
