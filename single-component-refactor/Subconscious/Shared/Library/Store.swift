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
    func update(action: Action) -> Self
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
protocol Modelable: Updatable, Effectable, Equatable {
    
}

/// Store is a source of truth for a central state.
/// It holds a model (typically a struct that conforms to `Modelable`) which represents app state.
/// All updates and effects happen through actions sent to `store.send`.
///
/// Following Elm, Store is meant to be used as a single app-wide, or major-view-wide model.
/// Deeply nested components are discouraged. Instead, the app should be a single component, or perhaps
/// one component per major view.
///
/// Components should never have to communicate with each other.
/// Instead of decomposing app into components, we decompose the app into many views that share the
/// same store and actions. This cuts down on the amount of mapping and unwrapping that must be done.
/// It also means we don't need machinery for republishing changes across multiple stores, and we don't
/// need to hold on to that redundant state.
///
/// Sub-views should be either stateless, consuming bare properties of `store.state`, or
/// take bindings, which can be created with `store.binding`.
final class Store<Model>: ObservableObject
where Model: Modelable
{
    private(set) var logger: Logger
    private(set) var debug: Bool
    private var cancellables = PublisherBag()
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

    func send(action: Model.Action) {
        let next = state.update(action: action)
        let effect = state.effect(action: action)
        if debug {
            let actionString = String(reflecting: action)
            let prevString = String(reflecting: self.state)
            let currString = String(reflecting: next)
            let effectString = String(reflecting: effect)
            logger.debug(
                """
                [send]
                Action: \(actionString)
                Prev: \(prevString)
                Next: \(currString)
                Effect: \(effectString)
                """
            )
        }
        // Check if state has changed before setting.
        // As a `@Published` property, state will fire for any willSet, even
        // for values that are equal. We cut down on uneccessary rendering by
        // checking for state equality before setting.
        if self.state != next {
            self.state = next
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
