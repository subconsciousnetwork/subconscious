//
//  FirstRunProfileView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/20/23.
//

import SwiftUI
import ObservableStore

struct FirstRunProfileView: View {
    /// FirstRunView is a major view that manages its own state in a store.
    @ObservedObject var store: Store<FirstRunModel>
    var onDone: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: AppTheme.unit4) {
                    TextFieldLabel(
                        label: Text("Your Nickname"),
                        caption: Text("Lowercase letters, numbers and dashes only."),
                        field: TextField(
                            "nickname",
                            text: Binding(
                                get: { store.state.nickname },
                                send: store.send,
                                tag: FirstRunAction.setNickname
                            )
                        )
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    )
                }
                Spacer()
                NavigationLink(
                    destination: {
                        FirstRunCreateSphereView(
                            store: store,
                            onDone: onDone
                        )
                    },
                    label: {
                        Text("Continue")
                    }
                )
                .buttonStyle(LargeButtonStyle())
                .disabled(!store.state.isNicknameValid)
                .simultaneousGesture(TapGesture().onEnded {
                    store.send(.persistProfile)
                })
            }
            .padding()
            .navigationTitle("Your Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct FirstRunProfileView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunProfileView(
            store: Store(
                state: FirstRunModel(),
                environment: AppEnvironment.default
            ),
            onDone: { id in }
        )
    }
}
