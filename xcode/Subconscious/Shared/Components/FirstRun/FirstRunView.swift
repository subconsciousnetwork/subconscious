//
//  FirstRunView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/19/23.
//
import ObservableStore
import SwiftUI

enum FirstRunAction: Hashable {
    case appear
    case createSphere
    case failCreateSphere(String)
    case setNickname(String)
    case persistProfile
}

struct FirstRunModel: ModelProtocol, Codable, Hashable {
    typealias Action = FirstRunAction
    typealias Environment = AppEnvironment
    
    var nickname: String = ""
    var sphereMnemonic: String?
    var sphereIdentity: String?
    
    var isNicknameValid: Bool {
        !nickname.isEmpty
    }

    static func update(
        state: FirstRunModel,
        action: FirstRunAction,
        environment: AppEnvironment
    ) -> Update<FirstRunModel> {
        switch action {
        case .appear:
            return appear(state: state, environment: environment)
        case .createSphere:
            return createSphere(
                state: state,
                environment: environment
            )
        case .failCreateSphere(let message):
            environment.logger.warning("Failed to create Sphere: \(message)")
            return Update(state: state)
        case .setNickname(let nickname):
            var model = state
            model.nickname = Nickname.format(nickname)
            return Update(state: model)
        case .persistProfile:
            return persistProfile(
                state: state,
                environment: environment
            )
        }
    }

    static func appear(
        state: FirstRunModel,
        environment: AppEnvironment
    ) -> Update<FirstRunModel> {
        // Does Sphere already exist? Get it and set on model
        if let identity = try? environment.data.sphereIdentity() {
            var model = state
            model.sphereIdentity = identity
            return Update(state: model)
        }
        return Update(state: state)
    }
    
    static func createSphere(
        state: FirstRunModel,
        environment: AppEnvironment
    ) -> Update<FirstRunModel> {
        do {
            let ownerKeyName = (
                state.nickname.isEmpty ?
                Config.default.noosphere.ownerKeyName :
                state.nickname
            )
            let receipt = try environment.data.createSphere(
                ownerKeyName: ownerKeyName
            )
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
    
    /// Save profile values
    static func persistProfile(
        state: FirstRunModel,
        environment: AppEnvironment
    ) -> Update<FirstRunModel> {
        environment.data.defaults.nickname.set(state.nickname)
        environment.logger.log("Saved nickname: \(state.nickname)")
        return Update(state: state)
    }
}

struct FirstRunView: View {
    /// FirstRunView is a major view that manages its own state in a store.
    /// Store for first run experience state
    @StateObject private var store = Store(
        state: FirstRunModel(),
        environment: AppEnvironment.default
    )
    var onDone: (String) -> Void

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
                            store: store,
                            onDone: onDone
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
        .onAppear {
            store.send(.appear)
        }
    }
}

struct FirstRunView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunView(
            onDone: { id in }
        )
    }
}
