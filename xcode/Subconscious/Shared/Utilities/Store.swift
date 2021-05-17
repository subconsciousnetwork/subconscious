//
//  Store.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/21/21.
//
//  Elm-like state store with effects support.

import Combine
import SwiftUI
import os

typealias Reducer<State, Action, Environment> =
    (inout State, Action, Environment) -> AnyPublisher<Action, Never>?

/// Store holds a single source of truth for your entire app.
/// SwiftUI updates can be driven by using the state variable as an `EnvironmentObject`.
/// Unlike a typical `@Binding`-driven model, you cannot set state directly.
/// Instead, store is udpdated deterministically by using `send` to dispatch actions to a reducer, which
/// is responsible for mutating the state. The same actions result in the same state.
/// Inspired by the [Elm App Architecture](https://guide.elm-lang.org/architecture/).
final class Store<State, Action, Environment>: ObservableObject, Equatable
    where State: Equatable {
    static func == (
        lhs: Store<State, Action, Environment>,
        rhs: Store<State, Action, Environment>
    ) -> Bool {
        lhs.state == rhs.state
    }
    
    @Published private(set) var state: State

    /// Holds references to things like services
    private let environment: Environment
    /// Mutates state in response to an action, returning an effect stream
    private let reducer: Reducer<State, Action, Environment>
    private var cancellables: Set<AnyCancellable> = []

    init(
        state: State,
        reducer: @escaping Reducer<State, Action, Environment>,
        environment: Environment
    ) {
        self.state = state
        self.reducer = reducer
        self.environment = environment
    }
    
    func send(_ action: Action) {
        guard let effect = reducer(&state, action, environment) else {
            return
        }
        
        let publisher = effect
            /// Specifies the schedular used to pull events
            /// <https://developer.apple.com/documentation/combine/fail/receive(on:options:)>
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        exhaustPublisherAndThenRelease(publisher: publisher, receiveValue: send)
    }
}

/// Consumes publisher, keeping it alive until it is complete.
/// After the publisher completes, it is cancelled so that it may be released from memory.
/// Ordinarily, an AnyCancellable self-cancels if a reference to it is not held somewhere.
/// See <https://www.apeth.com/UnderstandingCombine/subscribers/subscribersoneshot.html>
///
/// 2021-05-04 tested with timer to ensure the cancellable stays alive.
///
/// The alternative implementation would be to implement a queue that empties itself on completion
/// within send, as seen here:
/// <https://www.pointfree.co/collections/combine/introduction/ep81-the-combine-framework-and-effects-part-2>
/// <https://github.com/pointfreeco/swift-composable-architecture/blob/0f026d395d414efab5cfdf8d697ec0ae766dd021/Sources/ComposableArchitecture/Store.swift>
func exhaustPublisherAndThenRelease<Input, Failure:Error>(
    publisher: AnyPublisher<Input, Failure>,
    receiveValue: @escaping (Input) -> Void
) {
    var cancellable: AnyCancellable?
    cancellable = publisher.sink(
        receiveCompletion: { _ in
            cancellable?.cancel()
        },
        receiveValue: receiveValue
    )
}

/// ViewStore acts as a state container, typically for some view over the application's central store.
/// You construct a ViewStore and pass it to a subview. Because it is Equatable, you can
/// make the subview Equatable as well, with `.equatable()`. The subview will then only render
/// when the actual value of the state changes.
struct ViewStore<LocalState, LocalAction>: Equatable
    where LocalState: Equatable {
    static func == (
        lhs: ViewStore<LocalState, LocalAction>,
        rhs: ViewStore<LocalState, LocalAction>
    ) -> Bool {
        lhs.state == rhs.state
    }
    
    let state: LocalState
    let send: (LocalAction) -> Void
}

extension ViewStore {
    init<Action>(
        state: LocalState,
        send: @escaping (Action) -> Void,
        tag: @escaping (LocalAction) -> Action
    ) {
        self.state = state
        self.send = address(send: send, tag: tag)
    }
}

/// Creates a tagged send function that can be used in a sub-view.
/// The returned send function will tag local view actions on the way out.
func address<Action, LocalAction>(
    send: @escaping (Action) -> Void,
    tag: @escaping (LocalAction) -> Action
) -> (LocalAction) -> Void {
    return { localAction in
        send(tag(localAction))
    }
}


/// A generic struct in which you can box actions from lists of items in arrays or dictionaries
struct ItemAction<K, V> {
    var key: K;
    var action: V;
}
