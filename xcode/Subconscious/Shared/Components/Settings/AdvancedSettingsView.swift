//
//  AdvancedSettingsView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 12/18/23.
//

import SwiftUI
import ObservableStore

struct AdvancedSettingsView: View {
    @ObservedObject var app: Store<AppModel>
    var body: some View {
        Form {
            Section(footer: Text("Recovery mode rebuilds your local database from your sphere in the cloud.")) {
                Button(
                    action: {
                        app.send(.requestRecoveryMode(.userInitiated))
                    },
                    label: {
                        Text("Recovery Mode")
                    }
                )
            }
        }
    }
}

struct AdvancedSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedSettingsView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
