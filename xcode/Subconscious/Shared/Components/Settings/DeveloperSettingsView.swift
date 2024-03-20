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
            Section {
                Picker("Noosphere log detail", selection: app.binding(
                    get: \.noosphereLogLevel,
                    tag: AppAction.persistNoosphereLogLevel
                )) {
                    ForEach(Noosphere.NoosphereLogLevel.allCases, id: \.self) { level in
                        Text(level.description).tag(level)
                    }
                }
                .pickerStyle(DefaultPickerStyle())
            }
            
            Section(header: Text("AI Features")) {
                Toggle(
                    isOn: app.binding(
                        get: \.areAiFeaturesEnabled,
                        tag: AppAction.persistAiFeaturesEnabled
                    ),
                    label: {
                        Text("Enable AI Features")
                    }
                )
                
                if app.state.areAiFeaturesEnabled {
                    Picker("Preferred Model", selection: app.binding(
                        get: \.preferredLlm,
                        tag: AppAction.persistPreferredLlm
                    )) {
                        ForEach(OpenAIService.supportedModels, id: \.self) { model in
                            Text(model.description).tag(model)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                    
                    SecureField(
                        "Open AI API Key",
                        text: app.binding(
                            get: \.openAiApiKey.key,
                            tag: { key in AppAction.persistOpenAIKey(OpenAIKey(key: key)) }
                        )
                    )
                    .disableAutocorrection(true)
                }
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
