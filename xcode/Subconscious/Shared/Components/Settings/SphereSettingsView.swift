//
//  SphereSettingsView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 19/7/2023.
//

import SwiftUI
import ObservableStore
import os

struct SphereSettingsView: View {
    @ObservedObject var app: Store<AppModel>

    var body: some View {
        Form {
            NavigationLink(
                destination: {
                    AuthorizationSettingsView(app: app)
                },
                label: {
                    Text("Authorization")
                }
            )
            
            if let did = Did(app.state.sphereIdentity ?? "") {
                Section(header: Text("Your DID")) {
                    DidView(did: did)
                }
                
                Section(header: Text("Your QR Code")) {
                    ShareableDidQrCodeView(did: did, color: Color.gray)
                }
            }
        }
        .navigationTitle("Sphere Settings")
    }
}

struct SphereSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SphereSettingsView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
