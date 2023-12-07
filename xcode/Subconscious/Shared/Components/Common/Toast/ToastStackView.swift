//
//  ToastStackView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 30/10/2023.
//

import Foundation
import SwiftUI
import ObservableStore
import Combine

struct ToastStackView: View {
    var store: ViewStore<ToastStackModel>
    
    var body: some View {
        if let first = store.state.presented {
            ToastView(toast: first)
        }
    }
}

struct Toast: Equatable, Hashable {
    var id: UUID
    var message: String
    
    init(message: String) {
        self.id = UUID()
        self.message = message
    }
}

enum ToastStackAction: Hashable, Equatable {
    case pushToast(message: String)
    case toastPresented(_ toast: Toast)
    case toastExpired(_ toast: Toast)
}

struct ToastStackModel: ModelProtocol {
    typealias Action = ToastStackAction
    typealias Environment = AppEnvironment
    
    var stack: [Toast] = []
    var presented: Toast?
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        switch action {
        case .pushToast(message: let message):
            return pushToast(
                state: state,
                environment: environment,
                message: message
            )
        case .toastExpired(toast: let toast):
            return toastExpired(
                state: state,
                environment: environment,
                toast: toast
            )
        case .toastPresented(toast: let toast):
            return toastPresented(
                state: state,
                environment: environment,
                toast: toast
            )
        }
    }
    
    static func pushToast(
        state: Self,
        environment: Environment,
        message: String
    ) -> Update<Self> {
        var model = state
        model.stack.append(
            Toast(message: message)
        )
        
        // If this is the only toast, immediately present it
        if (model.stack.count == 1) {
            let fx: Fx<ToastStackAction> = Just(
                ToastStackAction.toastPresented(
                    model.stack.first!
                )
            ).eraseToAnyPublisher()
            return Update(state: model, fx: fx)
        }
        
        return Update(state: model)
    }
    
    static func toastExpired(
        state: Self,
        environment: Environment,
        toast: Toast
    ) -> Update<Self> {
        var model = state
        model.stack.removeAll(where: { $0.id == toast.id })
        
        if let first = model.stack.first {
            let fx: Fx<ToastStackAction> = Just(
                ToastStackAction.toastPresented(first)
            ).eraseToAnyPublisher()
            return Update(state: model, fx: fx)
        }
        
        model.presented = nil
        return Update(state: model).animation(.spring())
    }
    
    static func toastPresented(
        state: Self,
        environment: Environment,
        toast: Toast
    ) -> Update<Self> {
        var model = state
        let fx: Fx<ToastStackAction> = Future.detached {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            return .toastExpired(toast)
        }
        .eraseToAnyPublisher()
        model.presented = toast
        
        return Update(state: model, fx: fx).animation(.spring())
    }
}
