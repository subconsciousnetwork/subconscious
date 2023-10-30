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
    case toastPresented(toast: Toast)
    case toastExpired(toast: Toast)
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
            return update(
                state: model,
                action: .toastPresented(toast: model.stack.first!),
                environment: environment
            )
            .animation(.default)
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
            return update(
                state: model,
                action: .toastPresented(toast: first),
                environment: environment
            )
        }
        
        model.presented = nil
        return Update(state: model).animation(.default)
    }
    
    static func toastPresented(
        state: Self,
        environment: Environment,
        toast: Toast
    ) -> Update<Self> {
        var model = state
        let fx: Fx<ToastStackAction> = Future.detached {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            return .toastExpired(toast: toast)
        }
        .eraseToAnyPublisher()
        model.presented = toast
        
        return Update(state: model, fx: fx)
    }
}
