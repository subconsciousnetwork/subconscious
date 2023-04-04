//
//  FirstRunDoneView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/20/23.
//
import ObservableStore
import SwiftUI

struct FirstRunDoneView: View {
    @ObservedObject var app: Store<AppModel>

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                VStack(spacing: AppTheme.unit3) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 96))
                        .foregroundColor(.accentColor)
                    Text("All set!")
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(
                    action: {
                        app.send(.persistFirstRunComplete(true))
                    }
                ) {
                    Text("Continue")
                }
                .buttonStyle(PillButtonStyle())
                .disabled(app.state.sphereIdentity == nil)
            }
            .padding()
        }
    }
}

struct FirstRunDoneView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunDoneView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
