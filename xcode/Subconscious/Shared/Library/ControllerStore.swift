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

/// A type responsible for returning updates for state and controller
protocol ControllerStoreUpdateableProtocol: AnyObject {
    associatedtype Model
    associatedtype Action
    associatedtype Environment
    
    @MainActor
    func update(
        state: Model,
        action: Action,
        environment: Environment
    ) -> ControllerStore.Update<Model, Action>
}

extension ControllerStore {
    final class Store<Controller>: ObservableObject
    where Controller: ControllerStoreUpdateableProtocol
    {
        private let logger = Logger(
            subsystem: Bundle.main.bundleIdentifier!,
            category: "ControllerStore.Store"
        )
        
        private var _changes = PassthroughSubject<Controller.Model, Never>()
        var changes: AnyPublisher<Controller.Model, Never> {
            _changes.eraseToAnyPublisher()
        }
        
        private(set) var environment: Controller.Environment
        
        private(set) var state: Controller.Model
        
        weak var controller: Controller?
        
        init(
            state: Controller.Model,
            environment: Controller.Environment
        ) {
            self.state = state
            self.environment = environment
        }
        
        @MainActor
        func send(_ action: Controller.Action) {
            logger.debug("Action: \(String(describing: action))")
            guard let controller = self.controller else {
                logger.warning("Cannot transact without controller. Doing nothing.")
                return
            }
            let update = controller.update(
                state: state,
                action: action,
                environment: environment
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
                await self.send(action)
            }
        }
    }
}
