//
//  FirstRunView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/19/23.
//
import ObservableStore
import SwiftUI

struct FirstRunView: View {
    @ObservedObject var app: Store<AppModel>

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Image("sub_logo_light")
                    .resizable()
                    .frame(width: 128, height: 128)
                Spacer()
                VStack(alignment: .leading, spacing: AppTheme.unit3) {
                    Text("Subconscious is a place to garden thoughts and share with others.")
                    
                    Text("It's powered by a decentralized note graph. Your data is yours, forever.")
                }
                .foregroundColor(.secondary)
                .font(.callout)
                Spacer()
                NavigationLink(
                    destination: {
                        FirstRunProfileView(
                            app: app
                        )
                    },
                    label: {
                        Text("Get Started")
                    }
                )
                .buttonStyle(LargeButtonStyle())
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .padding()
        }
        .background(.background)
    }
}

struct FirstRunView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
