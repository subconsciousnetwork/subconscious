//
//  FirstRunDoneView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/20/23.
//
import ObservableStore
import SwiftUI

struct FirstRunDoneView: View {
    /// FirstRunView is a major view that manages its own state in a store.
    @ObservedObject var store: Store<FirstRunModel>
    var done: () -> Void

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
                Button(action: done) {
                    Text("Continue")
                }
            }
            .padding()
        }
    }
}

struct FirstRunDoneView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunDoneView(
            store: Store(
                state: FirstRunModel(),
                environment: AppEnvironment.default
            ),
            done: {}
        )
    }
}
