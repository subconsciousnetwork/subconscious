//
//  GatewaySettingsView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/4/23.
//

import SwiftUI
import ObservableStore

struct DeveloperSettingsView: View {
    @ObservedObject var app: Store<AppModel>

    var body: some View {
        Form {
            Button(
                action: {
                    app.send(.persistFirstRunComplete(false))
                },
                label: {
                    Text("Reset First Run Experience")
                }
            )
            
            Button(
                action: {
                    app.send(.resetIndex)
                },
                label: {
                    Text("Reset Local SQLite Index")
                }
            )
            
            Button(
                action: {
                    app.send(.indexOurSphere)
                },
                label: {
                    Text("Build Local SQLite Index")
                }
            )
            
            Section(footer: Text("The block editor is an experimental feature that is currently in-development. Not everything will work correctly.")) {
                Toggle(
                    isOn: app.binding(
                        get: \.isBlockEditorEnabled,
                        tag: AppAction.persistBlockEditorEnabled
                    ),
                    label: {
                        Text("Enable Block Editor")
                    }
                )
            }
            
            Section(footer: Text("Enable and disable experimental tabs")) {
                Toggle(
                    isOn: app.binding(
                        get: \.isFeedTabEnabled,
                        tag: AppAction.persistFeedTabEnabled
                    ),
                    label: {
                        Text("Enable Feed Tab")
                    }
                )
                Toggle(
                    isOn: app.binding(
                        get: \.isDeckTabEnabled,
                        tag: AppAction.persistDeckTabEnabled
                    ),
                    label: {
                        Text("Enable Deck Tab")
                    }
                )
            }
        }
        .navigationTitle("Developer")
    }
}

struct DeveloperSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperSettingsView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
