//
//  FirstRunCreateSphereView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/20/23.
//
import ObservableStore
import SwiftUI

struct FirstRunCreateSphereView: View {
    /// FirstRunView is a major view that manages its own state in a store.
    @ObservedObject var store: Store<FirstRunModel>
    var done: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                VStack(alignment: .leading) {
                    Text("Recovery Passphrase")
                        .font(.headline)
                    HStack {
                        Text(store.state.sphereMnemonic ?? "")
                            .monospaced()
                        Spacer()
                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLg)
                            .stroke(Color.separator, lineWidth: 0.5)
                    )
                    Text("This is your notebook recovery passphrase. It's for your eyes only. We don't store it. Write it down and keep it safe.")
                        .foregroundColor(.secondary)
                }
                Spacer()
                NavigationLink(
                    destination: {
                        FirstRunDoneView(store: store, done: done)
                    },
                    label: {
                        Text("Continue")
                    }
                )
            }
            .padding()
        }
    }
}

struct FirstRunCreateSphereView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunCreateSphereView(
            store: Store(
                state: FirstRunModel(),
                environment: AppEnvironment.default
            ),
            done: {}
        )
    }
}
