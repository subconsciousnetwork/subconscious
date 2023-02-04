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

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Profile Info")) {
                    NavigationLink(
                        destination: {},
                        label: {
                            VStack(alignment: .leading) {
                                Text("Gordon")
                                Text(verbatim: "you@there.com")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }
                        }
                    )
                }


                Section(header: Text("Noosphere")) {
                    Toggle("Enable Noosphere", isOn: .constant(false))
                }

                Section(header: Text("Sphere")) {
                    KeyValueRowView(
                        key: Text("Author"),
                        value: Text(
                            "asdfasdfasdfasdfasdfasdfasdfasdfasdfasdf"
                        )
                        .textSelection(.enabled)
                    )
                    KeyValueRowView(
                        key: Text("Sphere"),
                        value: Text(
                            "asdfasdfasdfasdfasdfasdfasdfasdfasdfasdf"
                        )
                        .textSelection(.enabled)
                    )
                    KeyValueRowView(
                        key: Text("Version"),
                        value: Text(
                            "asdfasdfasdfasdfasdfasdfasdfasdfasdfasdf"
                        )
                        .textSelection(.enabled)
                    )
                }
                
                Section(header: Text("Gateway")) {
                    KeyValueRowView(
                        key: Text("Gateway URL"),
                        value: Text(
                            "asdfasdfasdfasdfasdfasdfasdfasdfasdfasdf"
                        )
                        .textSelection(.enabled)
                    )
                    NavigationLink("Gateway Settings") {
                        GatewaySettingsView(app: app)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
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
