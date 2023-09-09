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
            
            Toggle(
                "Show App Tabs",
                isOn: Binding(
                    get: { app.state.appTabs },
                    send: app.send,
                    tag: AppAction.setAppTabs
                )
            )
            
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
