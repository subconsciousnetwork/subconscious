//
//  FABButtonStyle.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/14/21.
//

import SwiftUI
import SwiftSubsurface

/// Wraps
struct FABView: View {
    var image: Image = Image(systemName: "doc.text.magnifyingglass")
    var action: () -> Void

    var body: some View {
        Button(
            action: action,
            label: {
                image.font(.system(size: 20))
            }
        )
        .buttonStyle(
            FABButtonStyle(
                orbShaderEnabled: Config.default.orbShaderEnabled
            )
        )
    }
}

struct FABButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) var colorScheme
    var orbShaderEnabled: Bool
    
    private func brandGradient() -> [Gradient.Stop] {
        return colorScheme == .dark ? Color.brandDarkMarkGradient : Color.brandLightMarkGradient
    }
    
    private func brandInnerShadow() -> Color {
        return colorScheme == .dark ? Color.brandMarkPurple : Color.brandMarkPink
    }
    
    private func brandText() -> Color {
        return colorScheme == .dark ? Color.white : Color.brandBgSlate
    }
    
    private func brandDropShadow() -> Color {
        return colorScheme == .dark ? Color.brandMarkPink : Color.brandMarkPurple
    }

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            if orbShaderEnabled {
                SubsurfaceView(speed: 0.05, density: 0.75, corner_radius: 64)
                    .clipped()
                    .clipShape(Circle())
                    .frame(
                        width: AppTheme.fabSize,
                        height: AppTheme.fabSize,
                        alignment: .center
                    )
                    .shadow(
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            } else {
                Circle()
                    .foregroundStyle(
                        .radialGradient(
                            stops: brandGradient(),
                            center: .init(x: 0.5, y: 0.25),
                            startRadius: 0,
                            endRadius: AppTheme.fabSize * 0.75
                        )
                        .shadow(.inner(color: brandInnerShadow().opacity(0.5), radius: 5, x: 0, y: 0))
                    )
                    .frame(
                        width: AppTheme.fabSize,
                        height: AppTheme.fabSize,
                        alignment: .center
                    )
                    .shadow(
                        color: brandDropShadow().opacity(0.5),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            }
            configuration.label
                .foregroundColor(
                    isEnabled ? brandText() : Color.fabTextDisabled
                )
                .contentShape(
                    Circle()
                )
        }
        .scaleEffect(configuration.isPressed ? 0.8 : 1, anchor: .center)
        .animation(
            .easeOutCubic(duration: Duration.fast),
            value: configuration.isPressed
        )
        .animation(
            .easeOutCubic(duration: Duration.keyboard),
            value: isEnabled
        )
        .opacity(isEnabled ? 1 : 0)
        .transition(
            .opacity.combined(
                with: .scale(scale: 0.8, anchor: .center)
            )
        )
    }
}

struct FAB_Previews: PreviewProvider {
    static var previews: some View {
        FABView() { }
    }
}
