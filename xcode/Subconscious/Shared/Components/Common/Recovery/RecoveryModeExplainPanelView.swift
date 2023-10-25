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
                            .foregroundColor(.secondary)
                    }
                    .padding([.bottom], AppTheme.padding)
                }
                Text("Your local data is unreadable.")
                    .multilineTextAlignment(.center)
                
                Text(
                    "Subconscious will attempt to " +
                    "recover your data from your gateway, using your recovery phrase."
                )
                .multilineTextAlignment(.center)
                
               
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
                    "If your local data is damaged or unavailable you can recover your " +
                    "data from your gateway using your recovery phrase."
                )
                .multilineTextAlignment(.center)
                
            }
            
            Text(
                "We'll re-download and restore from the remote copy of your notes."
            )
            .multilineTextAlignment(.center)
            
            Spacer()
            
            NavigationLink("Proceed", value: RecoveryViewStep.form)
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
        }
        .padding(AppTheme.padding)
        .navigationTitle("Recovery Mode")
    }
}

struct RecoveryModeExplainPanel_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryModeExplainPanelView(
            store: Store(
                state: RecoveryModeModel(launchContext: .unreadableDatabase("Hello world")),
                environment: AppEnvironment()
            )
            .viewStore(
                get: { x in x},
                tag: { x in x }
            )
        )
    }
}
