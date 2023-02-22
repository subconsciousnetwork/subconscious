//
//  SettingsView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/3/23.
//

import SwiftUI
import ObservableStore

struct SettingsView: View {
    @ObservedObject var app: Store<AppModel>
    var unknown = "Unknown"

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Noosphere")) {
                    NavigationLink(
                        destination: {
                            ProfileSettingsView(app: app)
                        },
                        label: {
                            LabeledContent(
                                "Nickname",
                                value: app.state.nickname ?? ""
                            )
                            .lineLimit(1)
                            .textSelection(.enabled)
                        }
                    )
                    LabeledContent(
                        "Sphere",
                        value: app.state.sphereIdentity ?? unknown
                    )
                    .lineLimit(1)
                    .textSelection(.enabled)
                    LabeledContent(
                        "Version",
                        value: app.state.sphereVersion ?? unknown
                    )
                    .lineLimit(1)
                    .textSelection(.enabled)
                }
                
                Section(header: Text("Gateway")) {
                    NavigationLink(
                        destination: {
                            GatewayURLSettingsView(app: app)
                        },
                        label: {
                            LabeledContent(
                                "Gateway",
                                value: app.state.gatewayURL
                            )
                            .lineLimit(1)
                        }
                    )
                    Button(
                        action: {
                            app.send(.syncSphereWithGateway)
                        },
                        label: {
                            Text("Sync with Gateway")
                        }
                    )
                }

                Section {
                    NavigationLink("Developer Settings") {
                        DeveloperSettingsView(app: app)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        app.send(.presentSettingsSheet(false))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                app.send(.refreshSphereVersion)
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
