//
//  ProfileView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/6/23.
//

import SwiftUI
import ObservableStore

/// The major profile tab view
struct ProfileView: View {
    /// Global shared store
    @ObservedObject var app: Store<AppModel>
    /// Local major view store
    @StateObject private var store = Store(
        state: ProfileModel(),
        environment: AppEnvironment.default
    )

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

enum ProfileAction: Hashable {
    
}

struct ProfileModel: ModelProtocol {
    typealias Action = ProfileAction
    typealias Environment = AppEnvironment

    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        
    }
}
