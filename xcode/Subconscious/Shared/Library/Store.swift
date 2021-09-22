//
//  Store.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/15/21.
//

import Foundation
import Combine
import SwiftUI
import os

/// An Updatable is a type that knows how create updates and effects in response to actions.
/// Effects are Combine Publishers that produce Actions and never fail.
protocol Updatable {
    associatedtype Action
    func update(action: Action) -> (Self, AnyPublisher<Action, Never>)
}

/// Store is a source of truth for a central state.
///
/// Store is an `ObservableObject`. You use it in a view via `@ObservedObject`
/// or `@StateObject` to power view rendering.
///
/// Store has a `@Published` `state` that conforms to`Updatable` (typically a struct).
/// All updates and effects to this state happen through actions sent to `store.send`.
///
/// Store is meant to be used as part of a single app-wide, or major-view-wide component.
/// Store deliberately does not solve for nested components or nested stores. Following Elm,
/// deeply nested components are discouraged. Instead, the app should use a single store,
/// or perhaps one store per major view.
///
/// Components should not have to communicate with each other. If nested components do have to
/// communicate, it is probably a sign they should be the same component with a shared store.
///
/// Instead of decomposing an app into components, we decompose the app into sub-views that share the
/// same store and actions. This cuts down on the amount of mapping and unwrapping that must be done.
/// It also means we don't need machinery for republishing changes across nested stores, and we don't
/// need to hold on to redundant state across multiple components.
///
/// Sub-views should be either stateless, consuming bare properties of `store.state`, or
/// take bindings, which can be created with `store.binding`.
///
/// See https://guide.elm-lang.org/webapps/structure.html
/// for more about this philosophy.
final class Store<Model>: ObservableObject
where Model: Updatable
{
    /// Logger, used when in debug mode
    private(set) var logger: Logger
    /// Toggle debug mode
    private(set) var debug: Bool
    /// Holds on to cancellables until they complete
    private var cancellables = PublisherBag()
    /// Current state.
    /// All writes to state happen through actions sent to `Store.send`.
    @Published private(set) var state: Model

    init(
        state: Model,
        logger: Logger,
        debug: Bool = false
    ) {
        self.state = state
        self.logger = logger
        self.debug = debug
    }

    /// Create a binding for updating the store somehow.
    /// Updates are sent via actions, rather than setting values directly.
    func binding<Value>(
        get: @escaping (Model) -> Value,
        tag: @escaping (Value) -> Model.Action
    ) -> Binding<Value> {
        Binding(
            get: { get(self.state) },
            set: { value in
                self.send(action: tag(value))
            }
        )
    }

    /// Send an action to the store to update state and generate effects.
    /// Any effects generated are fed back into the store.
    func send(action: Model.Action) {
        // Generate next state and effect
        let (next, effect) = state.update(action: action)
        if debug {
            let actionString = String(reflecting: action)
            let previousStateString = String(reflecting: self.state)
            let nextStateString = String(reflecting: next)
            let effectString = String(reflecting: effect)
            logger.debug(
                """
                [send]
                Action: \(actionString)
                Previous State: \(previousStateString)
                Next State: \(nextStateString)
                Effect: \(effectString)
                """
            )
        }
        // Set state. This mutates published property, firing objectWillChange.
        self.state = next
        // Run effect
        cancellables.sink(
            publisher: effect.receive(
                on: DispatchQueue.main,
                options: .init(qos: .userInitiated)
            ).eraseToAnyPublisher(),
            receiveValue: self.send
        )
    }
}
