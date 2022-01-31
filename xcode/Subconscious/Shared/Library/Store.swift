//
//  Store.swift
//
//  Created by Gordon Brander on 9/15/21.
//
//  MIT LICENSE
//  Copyright 2021 Gordon Brander
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  allcopies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.

import Foundation
import Combine
import SwiftUI
import os

public struct Change<State, Action> {
    var state: State
    var fx: AnyPublisher<Action, Never>?
}

/// Store is a source of truth for a state.
///
/// Store is an `ObservableObject`. You can use it in a view via
/// `@ObservedObject` or `@StateObject` to power view rendering.
///
/// Store has a `@Published` `state` (typically a struct).
/// All updates and effects to this state happen through actions
/// sent to `store.send`.
///
/// Store is meant to be used as part of a single app-wide, or
/// major-view-wide component. Store deliberately does not solve for nested
/// components or nested stores. Following Elm, deeply nested components
/// are avoided. Instead, an app should use a single store, or perhaps one
/// store per major view. Components should not have to communicate with
/// each other. If nested components do have to communicate, it is
/// probably a sign they should be the same component with a shared store.
///
/// Instead of decomposing an app into components, we decompose the app into
/// views that share the same store and actions. Sub-views should be either
/// stateless, consuming bare properties of `store.state`, or take bindings,
/// which can be created with `store.binding`.
///
/// See https://guide.elm-lang.org/architecture/
/// and https://guide.elm-lang.org/webapps/structure.html
/// for more about this approach.
public final class Store<State, Action, Environment>: ObservableObject {
    /// Stores cancellables by ID
    private var cancellables: [UUID: AnyCancellable] = [:]
    /// Current state.
    /// All writes to state happen through actions sent to `Store.send`.
    @Published public private(set) var state: State
    /// Update function for state
    public private(set) var update: (
        State,
        Action,
        Environment
    ) -> Change<State, Action>
    /// Environment, which typically holds references to outside information,
    /// such as API methods.
    ///
    /// This is also a good place to put long-lived services, such as keyboard
    /// listeners, since its lifetime will match the lifetime of the Store.
    ///
    /// Tip: if you need to publish external events to the store, such as
    /// keyboard events, consider publishing them via a Combine Publisher on
    /// the environment. You can subscribe to the publisher in `update`, for
    /// example, by firing an action `onAppear`, then mapping the environment
    /// publisher to an `fx` and returning it as part of a `Change`.
    /// Store will hold on to the resulting `fx` publisher until it completes,
    /// which in the case of long-lived services, could be until the
    /// app is stopped.
    public var environment: Environment
    /// Logger, used when in debug mode
    public var logger: Logger
    /// Toggle debug mode
    public var debug: Bool

    init(
        update: @escaping (
            State,
            Action,
            Environment
        ) -> Change<State, Action>,
        state: State,
        environment: Environment,
        logger: Logger,
        debug: Bool = false
    ) {
        self.update = update
        self.state = state
        self.environment = environment
        self.logger = logger
        self.debug = debug
    }

    /// Create a binding that can update the store.
    /// Sets send actions to the store, rather than setting values directly.
    /// Optional `animation` parameter allows you to trigger an animation
    /// for binding sets.
    public func binding<Value>(
        get: @escaping (State) -> Value,
        tag: @escaping (Value) -> Action,
        animation: Animation? = nil
    ) -> Binding<Value> {
        Binding(
            get: { get(self.state) },
            set: { value in
                withAnimation(animation) {
                    self.send(action: tag(value))
                }
            }
        )
    }

    /// Subscribe to a publisher of actions, piping them through to
    /// the store.
    ///
    /// Holds on to the cancellable until publisher completes.
    /// When publisher completes, removes cancellable.
    public func subscribe(fx: AnyPublisher<Action, Never>) {
        // Create a UUID for the cancellable.
        // Store cancellable in dictionary by UUID.
        // Remove cancellable from dictionary upon effect completion.
        // This retains the effect pipeline for as long as it takes to complete
        // the effect, and then removes it, so we don't have a cancellables
        // memory leak.
        let id = UUID()
        let cancellable = fx.sink(
            receiveCompletion: { [weak self] _ in
                self?.cancellables.removeValue(forKey: id)
            },
            receiveValue: self.send
        )
        self.cancellables[id] = cancellable
    }

    /// Send an action to the store to update state and generate effects.
    /// Any effects generated are fed back into the store.
    ///
    /// Note: SwiftUI requires that all UI changes happen on main thread.
    /// We run effects as-given, without forcing them on to main thread.
    /// This means that main-thread effects will be run immediately, enabling
    /// you to drive things like withAnimation via actions.
    /// However it also means that publishers which run off-main-thread MUST
    /// make sure that they join the main thread (e.g. with
    /// `.receive(on: DispatchQueue.main)`).
    public func send(action: Action) {
        // Generate next state and effect
        let change = update(self.state, action, self.environment)
        if debug {
            logger.debug("Action: \(String(reflecting: action))")
            logger.debug("State: \(String(reflecting: change.state))")
        }
        // Set state. This mutates published property, firing objectWillChange.
        self.state = change.state
        // Run effect
        if let fx = change.fx {
            self.subscribe(fx: fx)
        }
    }
}
