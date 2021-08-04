//
//  Elmo.swift
//
//  Created by Gordon Brander on 4/21/21.
//
//  Elm-like state store with effects support.
import Combine
import SwiftUI
import os

public typealias Reducer<State, Action, Environment> =
    (inout State, Action, Environment) -> AnyPublisher<Action, Never>?

/// Store holds a single source of truth for your entire app.
/// SwiftUI updates can be driven by using the state variable as an `EnvironmentObject`.
/// Unlike a typical `@Binding`-driven model, you cannot set state directly.
/// Instead, store is udpdated deterministically by using `send` to dispatch actions to a reducer, which
/// is responsible for mutating the state. The same actions result in the same state.
/// Inspired by the [Elm App Architecture](https://guide.elm-lang.org/architecture/).
public final class Store<State, Action, Environment>: ObservableObject, Equatable
    where State: Equatable {
    public static func == (
        lhs: Store<State, Action, Environment>,
        rhs: Store<State, Action, Environment>
    ) -> Bool {
        lhs.state == rhs.state
    }

    @Published public private(set) var state: State

    private let logger: Logger?
    /// Holds references to things like services
    private let environment: Environment
    /// Mutates state in response to an action, returning an effect stream
    private let reducer: Reducer<State, Action, Environment>
    private let effects = PublisherManager()

    public init(
        state: State,
        reducer: @escaping Reducer<State, Action, Environment>,
        environment: Environment,
        logger: Logger? = nil
    ) {
        self.state = state
        self.reducer = reducer
        self.environment = environment
        self.logger = logger
    }

    /// Send an action to the store
    /// Note that this method is not thread-safe. This is by-design, since SwiftUI requires actions to be
    /// performed on the main thread, and some actions, like animation transactions to happen
    /// syncronously with state changes on the main thread.
    ///
    /// This means you...
    /// - Must always send from the main thread in your UI code.
    /// - Make sure your effects always deliver on the main thread via .receive(on:).
    public func send(_ action: Action) {
        if let logger = self.logger {
            let debug = String(reflecting: action)
            logger.debug(
                """
                Action: \(debug)
                """
            )
        }

        let effect = reducer(&state, action, environment)

        if let effect = effect {
            effects.sink(
                publisher: effect,
                receiveValue: self.send
            )
        }
    }
}

/// Holds cancellables returned by Publisher until the publisher completes.
///
/// Combine Publishers return a Cancellable that will automatically cancel the Publisher if the
/// Cancellable falls out of scope. Since Publishers can take some time to complete, you often
/// want to hold on to the Cancellable reference until the publisher has completed.
///
/// PublisherManager takes care of the boilerplate of holding on to Cancellables, and helps
/// you avoid the memory leak footgun of accidentally strong-referencing self in the completion handler.
///
/// The intent is to instantiate a long-lived instance of PublisherManager to manage multiple Publishers.
///
/// Publisher Cancellables are stored in a map by UUID.
/// The UUID is returned by `PublisherManager.sink`
/// You can also cancel a publisher by calling `PublisherManager.cancel` with the UUID.
public final class PublisherManager {
    /// Hashmap to store cancellables by ID
    private var cancellables: [UUID: AnyCancellable] = [:]

    /// Cancel a publisher by its id
    public func cancel(id: UUID) {
        let value = cancellables.removeValue(forKey: id)
        value?.cancel()
    }

    /// Similar in concept to `Publisher.sink` except that it holds on to the cancellable reference
    /// until the cancellable is complete.
    /// Returns a UUID that may be used with `cancel` to cancel the publisher.
    @discardableResult public func sink<T, E: Error> (
        publisher: AnyPublisher<T, E>,
        receiveValue: @escaping (T) -> Void
    ) -> UUID {
        // Create a UUID for the cancellable.
        // Store cancellable in dictionary by UUID.
        // Remove cancellable from dictionary upon effect completion.
        // This retains the effect pipeline for as long as it takes to complete
        // the effect, and then removes it, so we don't have a cancellables
        // memory leak.
        let id = UUID()
        let cancellable = publisher
            .sink(
                receiveCompletion: { [weak self] _ in
                    self?.cancellables.removeValue(forKey: id)
                },
                receiveValue: receiveValue
            )
        self.cancellables[id] = cancellable
        return id
    }
}

/// ViewStore acts as a state container, typically for some view over the application's central store.
/// You construct a ViewStore and pass it to a subview. Because it is Equatable, you can
/// make the subview Equatable as well, with `.equatable()`. The subview will then only render
/// when the actual value of the state changes.
public struct ViewStore<LocalState, LocalAction>: Equatable
    where LocalState: Equatable {
    public static func == (
        lhs: ViewStore<LocalState, LocalAction>,
        rhs: ViewStore<LocalState, LocalAction>
    ) -> Bool {
        lhs.state == rhs.state
    }

    public let state: LocalState
    public let send: (LocalAction) -> Void

    public init(
        state: LocalState,
        send: @escaping (LocalAction) -> Void
    ) {
        self.state = state
        self.send = send
    }

    public init<Action>(
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
public func address<Action, LocalAction>(
    send: @escaping (Action) -> Void,
    tag: @escaping (LocalAction) -> Action
) -> (LocalAction) -> Void {
    return { localAction in
        send(tag(localAction))
    }
}

/// A generic struct in which you can box actions from lists of items in arrays or dictionaries
public struct ItemAction<K, V> {
    public var key: K;
    public var action: V;

    public init(key: K, action: V) {
        self.key = key
        self.action = action
    }
}
