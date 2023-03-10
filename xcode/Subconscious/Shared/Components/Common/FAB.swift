//
//  FABButtonStyle.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/14/21.
//

import SwiftUI

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
            FABButtonStyle()
        )
    }
}

struct FABButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .foregroundStyle(
                    .radialGradient(
                        stops: Color.brandGradient(colorScheme),
                        center: .init(x: 0.5, y: 0.25), // Calculated from brandmark
                        startRadius: 0,
                        endRadius: AppTheme.fabSize * 0.75 // Calculated from brandmark
                    )
                    .shadow(
                        // Eyeballed from brandmark
                        .inner(
                            color: Color.brandInnerShadow(colorScheme).opacity(0.5),
                            radius: 5,
                            x: 0,
                            y: 0
                        )
                    )
                )
                .frame(
                    width: AppTheme.fabSize,
                    height: AppTheme.fabSize,
                    alignment: .center
                )
                .shadow(
                    color: Color.brandDropShadow(colorScheme).opacity(0.5),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            configuration.label
                .foregroundColor(
                    isEnabled ? Color.brandText(colorScheme) : Color.fabTextDisabled
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
