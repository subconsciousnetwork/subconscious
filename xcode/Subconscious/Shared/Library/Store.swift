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

/// A shorthand for Combine Publisher effect signature. We'll be typing this often.
typealias Effect<Action> = AnyPublisher<Action, Never>

/// An Updatable is a type that knows how to create a new instance of itself in response
/// to being passed an action.
protocol Updatable {
    associatedtype Action
    mutating func update(action: Action)
}

/// An Effectable is a type that knows how to create an `Effect` (Combine Publisher) in response
/// to an `Action` sent to `effect`.
protocol Effectable {
    associatedtype Action
    func effect(action: Action) -> Effect<Action>
}

/// A model that knows how to:
/// - Update itself in response to actions
/// - Generate effects (Combine publishers) in response to actions
/// Typically, you conform to Modelable with a simple struct that is used to model app state.
protocol Modelable: Updatable, Effectable {
    
}

/// Store is a source of truth for a central state.
///
/// Store is an `ObservableObject`. You use it in a view via `@ObservedObject`
/// or `@StateObject` to power view rendering.
///
/// Store has a `@Published` `state` that conforms to`Modelable` (typically a struct).
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
where Model: Modelable
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
        // Generate effect before mutating state.
        // This gives effect access to previous value.
        let effect = state.effect(action: action)
        // Then mutate model
        state.update(action: action)
        if debug {
            let actionString = String(reflecting: action)
            let stateString = String(reflecting: self.state)
            let effectString = String(reflecting: effect)
            logger.debug(
                """
                [send]
                Action: \(actionString)
                State: \(stateString)
                Effect: \(effectString)
                """
            )
        }
        cancellables.sink(
            publisher: effect.receive(
                on: DispatchQueue.main,
                options: .init(qos: .userInitiated)
            ).eraseToAnyPublisher(),
            receiveValue: self.send
        )
    }
}
