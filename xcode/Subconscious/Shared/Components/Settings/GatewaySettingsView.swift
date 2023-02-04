//
//  GatewaySettingsView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/4/23.
//

import SwiftUI
import ObservableStore

struct GatewaySettingsView: View {
    @ObservedObject var app: Store<AppModel>

    var body: some View {
        Form {
            Button(
                action: {
                    app.send(.syncSphereWithGateway)
                },
                label: {
                    Text("Sync with gateway")
                }
            )
        }
        .navigationTitle("Advanced")
    }
}

struct GatewaySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GatewaySettingsView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
