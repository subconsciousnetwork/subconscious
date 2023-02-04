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
                                Text("you@there.com")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    )
                }


                Section(header: Text("Noosphere")) {
                    Toggle("Enable Noosphere", isOn: .constant(false))
                    
                    NavigationLink("Gateway Settings") {
                        
                    }
                }

                Section(header: Text("Sphere")) {
                    Text("Author Key")
                    Text("Sphere Key")
                    Text("Sphere Version")
                }

                Section {
                    NavigationLink("Advanced") {
                        
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
