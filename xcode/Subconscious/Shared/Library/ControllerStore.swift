//
//  ControllerStore.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/22/23.
//
//  A store-like system for UIKit view controllers.
//  Since UIKit is based on a mutable DOM model, ControllerStore focuses on
//  describing actions that are passed to an update function which
//  produces discrete model updates paired with controller/view mutations.
//  Mutations are described as thunks and run by the controller store.
//
//  This enables us to create deterministic UI updates where the same actions
//  in the same order produce the same UI.

import Combine
import Foundation
import os
import UIKit

enum ControllerStore {}

extension ControllerStore {
    /// Represents a discrete state change and effects as a result of
    /// an action.
    struct Update<Model, Action> {
        typealias Effect = () async -> Action
        
        /// A description of the next state
        var state: Model
        /// A function that carries out a render
        /// (modification of the view tree) for this update.
        var render: (@MainActor () -> Void)?
        /// An array of side-effect for this update
        var effects: [Effect] = []
    }
}

protocol ControllerStoreControllerProtocol: AnyObject {
    associatedtype Model: Equatable
    associatedtype Action
    typealias Update = ControllerStore.Update<Model, Action>
    typealias Effect = ControllerStore.Update<Model, Action>.Effect
    
    @MainActor
    func reconfigure(
        state: Model,
        send: @escaping (Action) -> Void
    )
    
    @MainActor
    func update(
        state: Model,
        action: Action
    ) -> Update
}

extension ControllerStore {
    class Store<Controller>
    where Controller: ControllerStoreControllerProtocol
    {
        private let logger = Logger(
            subsystem: Bundle.main.bundleIdentifier!,
            category: "ControllerStore.Store"
        )
        private weak var controller: Controller?
        private var _changes = PassthroughSubject<Controller.Model, Never>()
        var changes: AnyPublisher<Controller.Model, Never> {
            _changes.eraseToAnyPublisher()
        }
        private(set) var state: Controller.Model

        init(
            state: Controller.Model
        ) {
            self.state = state
        }
        
        @MainActor
        func connect(_ controller: Controller) {
            logger.debug("Connect controller")
            controller.reconfigure(
                state: self.state,
                send: { [weak self] action in
                    self?.send(action)
                }
            )
            self.controller = controller
        }

        @MainActor
        func reset(
            controller: Controller,
            state: Controller.Model
        ) {
            if state != state || controller !== controller {
                logger.debug("Reset controller state")
                logger.debug("State: \(String(describing: state))")
                self.state = state
                connect(controller)
            }
        }

        @MainActor
        func transact(_ action: Controller.Action) {
            logger.debug("Action: \(String(describing: action))")
            guard let controller = self.controller else {
                logger.warning("Cannot transact without controller. Doing nothing.")
                return
            }
            let update = controller.update(
                state: state,
                action: action
            )
            self.state = update.state
            logger.debug("State: \(String(describing: self.state))")
            _changes.send(self.state)
            if let render = update.render {
                render()
                logger.debug("Rendered")
            }
            logger.debug("Effects: \(String(describing: update.effects.count))")
            for effect in update.effects {
                self.run(effect)
            }
        }

        func run(_ effect: @escaping () async -> Controller.Action) {
            Task.detached {
                let action = await effect()
                self.send(action)
            }
        }

        func send(_ action: Controller.Action) {
            Task { @MainActor in
                self.transact(action)
            }
        }
    }
}
