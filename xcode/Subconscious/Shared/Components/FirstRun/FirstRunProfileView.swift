//
//  FirstRunProfileView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/20/23.
//

import SwiftUI
import ObservableStore

struct FirstRunProfileView: View {
    @ObservedObject var app: Store<AppModel>
    @Environment(\.colorScheme) var colorScheme
    
    private var bgGradient: LinearGradient {
        switch colorScheme {
        case .dark:
            return Color.bgGradientDark
        default:
            return Color.bgGradientLight
        }
    }

    private var shadow: Color {
        switch colorScheme {
        case .dark:
            return .brandBgPurple
        default:
            return .brandMarkPurple
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: AppTheme.unit4) {
                    ValidatedTextField(
                        placeholder: "nickname",
                        text: Binding(
                            get: { app.state.nicknameFormFieldValue },
                            send: app.send,
                            tag: AppAction.setNickname
                        ),
                        caption: "Lowercase letters, numbers and dashes only.",
                        hasError: !app.state.isNicknameFormFieldValid
                    )
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .shadow(color: shadow, radius: 72)
                }
                Spacer()
                NavigationLink(
                    destination: {
                        FirstRunCreateSphereView(app: app)
                    },
                    label: {
                        Text("Continue")
                    }
                )
                .buttonStyle(PillButtonStyle())
                .simultaneousGesture(TapGesture().onEnded {
                    app.send(.createSphere)
                })
                .disabled(!app.state.isNicknameFormFieldValid)
            }
            .padding()
            .navigationTitle("Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .background(bgGradient)
        }
    }
}

struct FirstRunProfileView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunProfileView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
