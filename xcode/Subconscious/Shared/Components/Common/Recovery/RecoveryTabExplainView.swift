//
//  RecoveryTabExplainView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 25/9/2023.
//

import Foundation
import SwiftUI
import ObservableStore

struct RecoveryTabExplainView: View {
    var store: ViewStore<RecoveryModeModel>
    var did: Did?
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.padding) {
            Text("Recovery Mode")
                .bold()
            
            Spacer()
            
            switch store.state.launchContext {
            case .unreadableDatabase(let error):
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
                
                ErrorDetailView(error: error)
                
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
                "We'll download and restore from the remote copy of your notes."
            )
            .multilineTextAlignment(.center)
            
            Spacer()
            
            Button(
                action: {
                    store.send(.setCurrentTab(.form))
                },
                label: {
                    Text("Proceed")
                }
            )
            .buttonStyle(PillButtonStyle())
            
            if store.state.launchContext == .userInitiated {
                Button(
                    action: {
                        onCancel()
                    },
                    label: {
                        Text("Cancel")
                    }
                )
            }
        }
        .padding(AppTheme.padding)
    }
}
