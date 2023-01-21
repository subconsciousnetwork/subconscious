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
    var done: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                VStack(alignment: .leading) {
                    Text("Recovery Phrase")
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
                    VStack(alignment: .leading, spacing: AppTheme.unit2) {
                        Text("This is your notebook's secret recovery phrase. You can use it to recover your data.")
                            .foregroundColor(.secondary)
                        Text("Your recovery phrase is for your eyes only. We don't store it. Write it down. Keep it secret, keep it safe.")
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                NavigationLink(
                    destination: {
                        FirstRunDoneView(store: store, done: done)
                    },
                    label: {
                        Text("Ok, I wrote it down")
                    }
                )
            }
            .padding()
        }
        .task {
            store.send(.createSphere)
        }
        .navigationTitle("Recovery Phrase")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FirstRunCreateSphereView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunCreateSphereView(
            store: Store(
                state: FirstRunModel(),
                environment: AppEnvironment.default
            ),
            done: { id in }
        )
    }
}
