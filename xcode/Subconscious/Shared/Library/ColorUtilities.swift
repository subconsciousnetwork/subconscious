//
//  ColorUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 12/15/21.
//

import SwiftUI

extension Color {
    /// A color theme describes a foreground, background, and border
    struct Theme: Hashable {
        var foreground: Color
        var background: Color
    }
}

extension View {
    /// Apply a theme to this view
    func theme(_ theme: Color.Theme) -> some View {
        self
            .foregroundStyle(theme.foreground)
            .background(theme.background)
    }
}



extension Color {
    /// Describe themes for all states of a button
    struct ButtonTheme: Hashable {
        var normal: Theme
        var pressed: Theme
        var disabled: Theme

        /// Describes a button state
        enum State: Hashable {
            case normal
            case pressed
            case disabled

            init(
                isPressed: Bool,
                isEnabled: Bool = true
            ) {
                guard isEnabled else {
                    self = .disabled
                    return
                }
                guard !isPressed else {
                    self = .pressed
                    return
                }
                self = .normal
            }
        }

        /// Choose a theme given a button state
        func choose(_ state: ButtonTheme.State) -> Theme {
            switch state {
            case .normal:
                return normal
            case .pressed:
                return pressed
            case .disabled:
                return disabled
            }
        }
    }
}

extension View {
    /// Apply a button theme to this view for a given state
    func theme(
        _ buttonTheme: Color.ButtonTheme,
        state: Color.ButtonTheme.State
    ) -> some View {
        let theme = buttonTheme.choose(state)
        return self
            .animation(.default, value: state)
            .theme(theme)
    }
    
    /// Apply a button theme to this view depending on whether it is
    /// enabled, pressed, etc.
    func theme(
        _ buttonTheme: Color.ButtonTheme,
        isPressed: Bool,
        isEnabled: Bool = true
    ) -> some View {
        theme(
            buttonTheme,
            state: .init(isPressed: isPressed, isEnabled: isEnabled)
        )
    }
}

extension Color {
    /// Describe button themes for multiple roles
    struct ButtonRoleTheme: Hashable {
        var normal: ButtonTheme
        var destructive: ButtonTheme

        func forRole(_ buttonRole: ButtonRole? = nil) -> ButtonTheme {
            switch buttonRole {
            case let .some(role) where role == .destructive:
                return destructive
            default:
                return normal
            }
        }
    }
}

extension Color {
    static func chooseForState(
        isPressed: Bool,
        isEnabled: Bool,
        normal: Color,
        pressed: Color,
        disabled: Color
    ) -> Color {
        if !isEnabled {
            return disabled
        } else {
            if isPressed {
                return pressed
            } else {
                return normal
            }
        }
    }
}

struct ColorUtilities_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Hello world")
                .padding()
                .theme(
                    .init(
                        foreground: .blue,
                        background: .secondaryBackground
                    )
                )
            Text("Hello world")
                .padding()
                .theme(
                    .init(
                        foreground: .red,
                        background: .secondaryBackground
                    )
                )
        }
    }
}
