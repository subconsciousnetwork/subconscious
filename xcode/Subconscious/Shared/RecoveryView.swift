//
//  RecoveryView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 13/9/2023.
//

import Foundation
import SwiftUI
import ObservableStore
import Combine
import os

struct AttemptRecoveryLabel: View {
    var status: ResourceStatus
    
    var label: String {
        switch (status) {
        case .initial:
            return "Attempt Recovery"
        case .pending:
            return "Recovering..."
        case .failed:
            return "Recovery Failed"
        case .succeeded:
            return "Recovery Complete"
        }
    }
    
    var color: Color {
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

enum RecoveryViewTab {
    case explain
    case form
}

struct RecoveryView: View {
    @ObservedObject var app: Store<AppModel>
    @State var selectedTab = RecoveryViewTab.explain // TODO: move to a small, local store
    
    var body: some View {
        TabView(selection: $selectedTab) {
            VStack(spacing: AppTheme.padding) {
                Text("Recovery Mode")
                    .bold()
                    .padding(.bottom)
                
                Spacer()
                
                Image(systemName: "stethoscope")
                    .resizable()
                    .frame(width: 96, height: 96)
                    .foregroundColor(.secondary)
                
                Text(
                    "If you ever lose your device or experience data loss,"
                     + " you can recover your data using your recovery phrase and your gateway."
                )
                .multilineTextAlignment(.center)
                
                Text(
                    "We'll attempt to download and restore from the remote copy of your notes."
                )
                .multilineTextAlignment(.center)
                
                Spacer()
                
                Button(
                    action: {
                        withAnimation {
                            selectedTab = .form
                        }
                    },
                    label: {
                        Text("Proceed")
                    }
                )
                .buttonStyle(PillButtonStyle())
                
                Button(
                    action: {
                        app.send(.presentRecoveryMode(false))
                    },
                    label: {
                        Text("Cancel")
                    }
                )
                
                Spacer()
            }
            .padding(AppTheme.padding)
            .tabItem {
                Text("Recovery")
            }
            .tag(RecoveryViewTab.explain)
            
            Form {
                Section(
                    content: {
                        ValidatedFormField(
                            placeholder: "did:key:abc",
                            field: app.state.recoveryDidField,
                            send: Address.forward(
                                send: app.send,
                                tag: AppAction.recoveryDidField
                            ),
                            caption: "The identity of your sphere"
                        )
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        
                        ValidatedFormField(
                            placeholder: "http://example.com",
                            field: app.state.gatewayURLField,
                            send: Address.forward(
                                send: app.send,
                                tag: AppAction.gatewayURLField
                            ),
                            caption: String(localized: "The URL of your preferred Noosphere gateway")
                        )
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .onDisappear {
                            app.send(.submitGatewayURLForm)
                        }
                        .disabled(app.state.gatewayOperationInProgress)
                        
                        ValidatedFormField(
                            placeholder: "one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty-one twenty-two tenty-three twenty-four",
                            field: app.state.recoveryPhraseField,
                            send: Address.forward(
                                send: app.send,
                                tag: AppAction.recoveryPhraseField
                            ),
                            caption: "Recovery phrase",
                            axis: .vertical
                        )
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        
                        Button(
                            action: {
                                app.send(.requestRecovery)
                            },
                            label: {
                                AttemptRecoveryLabel(status: app.state.recoveryStatus)
                            }
                        )
                    },
                    header: {
                        Text("Recovery")
                    }
                )
            }
            .tabItem {
                Text("Form")
            }
            .tag(RecoveryViewTab.form)
        }
        .tabViewStyle(.page)
    }
}
