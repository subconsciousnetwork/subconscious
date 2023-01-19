//
//  FirstRunView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/19/23.
//
import ObservableStore
import SwiftUI

enum FirstRunAction: Hashable {
    case createSphere
    case failCreateSphere(String)
}

struct FirstRunModel: ModelProtocol, Codable, Hashable {
    typealias Action = FirstRunAction
    typealias Environment = AppEnvironment
    
    var sphereMnemonic: String?
    var sphereIdentity: String?
    
    static func update(
        state: FirstRunModel,
        action: FirstRunAction,
        environment: AppEnvironment
    ) -> Update<FirstRunModel> {
        switch action {
        case .createSphere:
            return createSphere(state: state, environment: environment)
        case .failCreateSphere(let message):
            environment.logger.warning("Failed to create Sphere: \(message)")
            return Update(state: state)
        }
    }
    
    static func createSphere(
        state: FirstRunModel,
        environment: AppEnvironment
    ) -> Update<FirstRunModel> {
        do {
            let receipt = try environment.noosphere.createSphereIfNeeded()
            var model = state
            model.sphereMnemonic = receipt.mnemonic
            model.sphereIdentity = receipt.identity
            return Update(state: model)
        }  catch {
            return update(
                state: state,
                action: .failCreateSphere(error.localizedDescription),
                environment: environment
            )
        }
    }
}

struct FirstRunView: View {
    /// FirstRunView is a major view that manages its own state in a store.
    @ObservedObject var store: Store<FirstRunModel>

    var body: some View {
        NavigationStack {
            VStack {
                Image("sub_logo_light")
                    .resizable()
                    .frame(width: 96, height: 96)
                Text("Welcome to Subconscious")
                    .foregroundColor(.secondary)
                Spacer()
                NavigationLink(
                    destination: {
                        FirstRunCreateSphereView(store: store)
                    },
                    label: {
                        Text("Get Started")
                    }
                )
            }
        }
        .task {
            store.send(.createSphere)
        }
    }
}

struct FirstRunCreateSphereView: View {
    /// FirstRunView is a major view that manages its own state in a store.
    @ObservedObject var store: Store<FirstRunModel>

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
                }
                Text("This is your notebook's recovery passphrase. It's for you alone. We don't store it. Write it down someplace, keep it safe.")
                    .foregroundColor(.secondary)
                Spacer()
                NavigationLink(
                    destination: {},
                    label: {
                        Text("Continue")
                    }
                )
            }
            .padding()
        }
    }
}

struct FirstRunView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunView(
            store: Store(
                state: FirstRunModel(),
                environment: AppEnvironment()
            )
        )
    }
}
