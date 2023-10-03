//
//  FirstRunCreateSphereView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/20/23.
//
import ObservableStore
import SwiftUI

struct FirstRunSphereView: View {
    @ObservedObject var app: Store<AppModel>
    @Environment(\.colorScheme) var colorScheme
    
    var did: Did? {
        Did(app.state.sphereIdentity ?? "")
    }
    
    var body: some View {
        VStack(spacing: AppTheme.padding) {
            Spacer()
            
            FirstRunOrbitEffectView()
            
            Spacer()
            
            Group {
                
                Text("Subconscious stores your notes in your personal sphere.")
                    .foregroundColor(.secondary)
                
                Text("Your sphere connects to other spheres, allowing you to follow other users.")
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            
            Spacer()
            
            Button(action: {
                app.send(.submitFirstRunSphereStep)
            }, label: {
                Text("Create Sphere")
            })
            .buttonStyle(PillButtonStyle())
        }
        .padding()
        .background(
            AppTheme.onboarding
                .appBackgroundGradient(colorScheme)
        )
        .navigationTitle("Create Sphere")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FirstRunSphereView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunSphereView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
