//
//  SettingsView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/3/23.
//

import SwiftUI
import ObservableStore

struct GatewaySyncLabel: View {
    var status: ResourceStatus
    
    private var label: String {
        switch status {
        case .initial:
            return "Sync with Gateway"
        case .pending:
            return "Syncing..."
        case .failed:
            return "Sync Failed"
        case .succeeded:
            return "Sync Complete"
        }
    }
    
    private var color: Color {
        switch status {
        case .failed:
            return .red
        default:
            return .accentColor
        }
    }

    var body: some View {
        Label(title: {
            Text(label)
        }, icon: {
            ResourceSyncBadge(status: status)
        })
        .foregroundColor(color)
    }
}

// MARK: Settings

struct SettingsView: View {
    @ObservedObject var app: Store<AppModel>
    var unknown = String(localized: "Unknown")
    
    var body: some View {
        NavigationStack {
            Form {
                Section(
                    content:  {
                        NavigationLink(
                            destination: {
                                ProfileSettingsView(app: app)
                            },
                            label: {
                                LabeledContent(
                                    "Nickname",
                                    value: app.state.nickname
                                )
                                .lineLimit(1)
                                .textSelection(.enabled)
                            }
                        )
                        
                        NavigationLink(
                            destination: {
                                SphereSettingsView(app: app)
                            },
                            label: {
                                LabeledContent(
                                    "Sphere",
                                    value: app.state.sphereIdentity?.description ?? unknown
                                )
                                .lineLimit(1)
                            }
                        )
                        
                        LabeledContent(
                            "Version",
                            value: app.state.sphereVersion ?? unknown
                        )
                        .lineLimit(1)
                        .textSelection(.enabled)
                        
                        let syncFailed: Bool = Func.run {
                            switch app.state.lastGatewaySyncStatus {
                            case .failed:
                                return true
                            default:
                                return false
                            }
                        }
                        
                        NavigationLink(
                            destination: {
                                GatewayURLSettingsView(app: app)
                            },
                            label: {
                                HStack {
                                    if (syncFailed) {
                                        Image(
                                            systemName: "exclamationmark.arrow.triangle.2.circlepath"
                                        )
                                    }
                                    LabeledContent(
                                        "Gateway",
                                        value: app.state.gatewayURL
                                    )
                                    .lineLimit(1)
                                }
                            }
                        )
                        .foregroundColor(syncFailed ? .red : nil)
                    },
                    header: {
                        Text("Noosphere")
                    },
                    footer: { }
                )
                
                SwiftUI.Link(
                    destination: Config.default.feedbackURL,
                    label: {
                        Text("Share feedback")
                    }
                )
                
                Section(
                    content: {
                        NavigationLink("Advanced") {
                            AdvancedSettingsView(app: app)
                        }
                        NavigationLink("Developer") {
                            DeveloperSettingsView(app: app)
                        }
                    },
                    footer: {
                        VStack(
                            alignment: .leading,
                            spacing: AppTheme.unit
                        ) {
                            Text("Version: v\(Bundle.main.version ?? unknown) (\(Bundle.main.buildVersion ?? unknown))")
                            Text("Noosphere: \(Config.default.noosphere.version)")
                        }
                    }
                )
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
