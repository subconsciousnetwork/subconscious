//
//  FirstRunView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/19/23.
//
import ObservableStore
import SwiftUI

enum FirstRunAction: Hashable {
    case start
    case createSphere
    case failCreateSphere(String)
    case setNickname(String)
    case setEmail(String)
}

struct FirstRunModel: ModelProtocol, Codable, Hashable {
    typealias Action = FirstRunAction
    typealias Environment = AppEnvironment
    
    var nickname: String = ""
    var email: String = ""
    var sphereMnemonic: String?
    var sphereIdentity: String?
    
    static func update(
        state: FirstRunModel,
        action: FirstRunAction,
        environment: AppEnvironment
    ) -> Update<FirstRunModel> {
        switch action {
        case .start:
            return start(state: state, environment: environment)
        case .createSphere:
            return createSphere(state: state, environment: environment)
        case .failCreateSphere(let message):
            environment.logger.warning("Failed to create Sphere: \(message)")
            return Update(state: state)
        case .setNickname(let nickname):
            var model = state
            model.nickname = nickname
            return Update(state: model)
        case .setEmail(var email):
            var model = state
            model.email = email
            return Update(state: model)
        }
    }
    
    static func start(
        state: FirstRunModel,
        environment: AppEnvironment
    ) -> Update<FirstRunModel> {
        // Does Sphere already exist? Get it and set on model
        if let sphereIdentity = environment.noosphere.getSphereIdentity() {
            var model = state
            model.sphereIdentity = sphereIdentity
            return Update(state: model)
        }
        // Otherwise create a sphere
        return update(
            state: state,
            action: .createSphere,
            environment: environment
        )
    }

    static func createSphere(
        state: FirstRunModel,
        environment: AppEnvironment
    ) -> Update<FirstRunModel> {
        do {
            let receipt = try environment.noosphere.createSphere()
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
    var done: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Image("sub_logo_light")
                    .resizable()
                    .frame(width: 128, height: 128)
                Spacer()
                VStack(alignment: .leading, spacing: AppTheme.unit3) {
                    Text("Welcome to Subconscious, a place to garden thoughts and share them with others.")
                    
                    Text("Subconscious is powered by an open and decentralized note graph. Your data is yours, forever.")
                }
                .foregroundColor(.secondary)
                .font(.callout)
                Spacer()
                NavigationLink(
                    destination: {
                        FirstRunCreateSphereView(
                            store: store,
                            done: done
                        )
                    },
                    label: {
                        Text("Get Started")
                    }
                )
            }
            .padding()
        }
        .background(.background)
        .task {
            store.send(.start)
        }
    }
}

struct FirstRunView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunView(
            store: Store(
                state: FirstRunModel(),
                environment: AppEnvironment()
            ),
            done: {}
        )
    }
}
