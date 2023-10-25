//
//  RecoveryModeExplainPanelView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 25/9/2023.
//

import Foundation
import SwiftUI
import ObservableStore

struct RecoveryModeExplainPanelView: View {
    var store: ViewStore<RecoveryModeModel>
    
    var did: Did? {
        store.state.recoveryDidField.validated
    }
    
    var body: some View {
        VStack(spacing: AppTheme.padding) {
            Spacer()
            
            switch store.state.launchContext {
            case .unreadableDatabase(_):
                if let did = did {
                    ZStack {
                        StackedGlowingImage() {
                            GenerativeProfilePic(
                                did: did,
                                size: 128
                            )
                        }
                        .padding(AppTheme.padding)
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                            .offset(x: 48, y: 48)
                            .foregroundColor(.secondaryIcon)
                    }
                    .padding([.bottom], AppTheme.padding)
                }
                Text(
                    "Your sphere ran into a problem and needs to be recovered."
                )
                .expandAlignedLeading()
                
                Text(
                    "Subconscious will download and restore your data from the gateway, using your recovery phrase."
                )
                .expandAlignedLeading()
                
               
            case .userInitiated:
                if let did = did {
                    StackedGlowingImage() {
                        ZStack {
                            Image(systemName: "stethoscope")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 128, height: 128)
                                .foregroundColor(.secondary)
                                .offset(x: -16)
                            GenerativeProfilePic(
                                did: did,
                                size: 64
                            )
                            .offset(x: 52, y: 52)
                        }
                    }
                    .padding(AppTheme.padding)
                }
                Spacer()
                Text(
                    "If your sphere data is damaged or unavailable, you can download and restore your data from your gateway, using your recovery phrase."
                )
                .expandAlignedLeading()
            }
            
            switch store.state.launchContext {
            case .unreadableDatabase(let error):
                ErrorDetailView(
                    error: error,
                    isExpanded: store.binding(
                        get: \.isDebugDetailExpanded,
                        tag: RecoveryModeAction.setDebugDetailExpanded
                    )
                )
            default:
                EmptyView()
            }

            Spacer()
            
            NavigationLink("Next", value: RecoveryViewStep.form)
                .buttonStyle(PillButtonStyle())
            
            if store.state.launchContext == .userInitiated {
                Button(
                    action: {
                        store.send(.requestPresent(false))
                    },
                    label: {
                        Text("Cancel")
                    }
                )
            }
        }
        .padding(AppTheme.padding)
        .navigationTitle("Recovery Mode")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RecoveryModeExplainPanel_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RecoveryModeExplainPanelView(
                store: Store(
                    state: RecoveryModeModel(
                        launchContext: .unreadableDatabase("Hello world"),
                        isDebugDetailExpanded: false,
                        recoveryDidField: RecoveryDidFormField(
                            value: "did:key:abc123",
                            validate: { string in Did(string) }
                        )
                    ),
                    environment: AppEnvironment()
                )
                .viewStore(
                    get: { x in x},
                    tag: { x in x }
                )
            )
        }

        NavigationStack {
            RecoveryModeExplainPanelView(
                store: Store(
                    state: RecoveryModeModel(
                        launchContext: .unreadableDatabase("Hello world"),
                        isDebugDetailExpanded: true,
                        recoveryDidField: RecoveryDidFormField(
                            value: "did:key:abc123",
                            validate: { string in Did(string) }
                        )
                    ),
                    environment: AppEnvironment()
                )
                .viewStore(
                    get: { x in x},
                    tag: { x in x }
                )
            )
        }

        NavigationStack {
            RecoveryModeExplainPanelView(
                store: Store(
                    state: RecoveryModeModel(
                        launchContext: .userInitiated,
                        isDebugDetailExpanded: false,
                        recoveryDidField: RecoveryDidFormField(
                            value: "did:key:abc123",
                            validate: { string in Did(string) }
                        )
                    ),
                    environment: AppEnvironment()
                )
                .viewStore(
                    get: { x in x},
                    tag: { x in x }
                )
            )
        }
    }
}
