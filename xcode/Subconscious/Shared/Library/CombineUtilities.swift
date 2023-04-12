//
//  CombineUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 6/14/21.
//

import Foundation
import Combine

struct CombineUtilities {
    /// Run a function asyncronously on the global DispatchQueue.
    static func async<T>(
        qos: DispatchQoS.QoSClass = .default,
        execute: @escaping () -> T
    ) -> AnyPublisher<T, Never> {
        Future({ promise in
            DispatchQueue.global(qos: qos).async(execute: {
                let result: T = execute()
                promise(.success(result))
            })
        })
        .eraseToAnyPublisher()
    }

    /// Run a throwing function asyncronously on the global DispatchQueue.
    static func async<T>(
        qos: DispatchQoS.QoSClass = .default,
        execute: @escaping () throws -> T
    ) -> AnyPublisher<T, Error> {
        Future({ promise in
            DispatchQueue.global(qos: qos).async(execute: {
                do {
                    let success: T = try execute()
                    promise(.success(success))
                } catch {
                    promise(.failure(error))
                }
            })
        })
        .eraseToAnyPublisher()
    }
}

/// Create a Combine Future from an async closure that never fails.
/// Async actions are run in a task and fulfil the future's promise.
public extension Future where Failure == Never {
    convenience init(
        priority: TaskPriority? = nil,
        _ perform: @escaping () async -> Output
    ) {
        self.init { promise in
            Task(priority: priority) {
                let value = await perform()
                promise(.success(value))
            }
        }
    }
}

/// Create a Combine Future from an async closure that never fails.
/// Async actions are run in a detatched task and fulfil the future's promise.
public extension Future where Failure == Never {
    static func detatched(
        priority: TaskPriority? = nil,
        perform: @escaping () async -> Output
    ) -> Self {
        self.init { promise in
            Task.detached(priority: priority) {
                let value = await perform()
                promise(.success(value))
            }
        }
    }
}

/// Create a Combine Future from an async closure that never fails.
/// Async actions are run in a task and fulfil the future's promise.
public extension Future where Failure == Error {
    convenience init(
        priority: TaskPriority? = nil,
        _ perform: @escaping () async throws -> Output
    ) {
        self.init { promise in
            Task(priority: priority) {
                do {
                    let value = try await perform()
                    promise(.success(value))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
}

/// Create a Combine Future from an async closure that never fails.
/// Async actions are run in a detatched task and fulfil the future's promise.
public extension Future where Failure == Error {
    static func detatched(
        priority: TaskPriority? = nil,
        perform: @escaping () async throws -> Output
    ) -> Self {
        self.init { promise in
            Task.detached(priority: priority) {
                do {
                    let value = try await perform()
                    promise(.success(value))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
}

extension DispatchQueue {
    /// Run a closure async on this queue, returning a Combine Future.
    func future<T>(
        qos: DispatchQoS = .unspecified,
        perform: @escaping () throws -> T
    ) -> Future<T, Error> {
        Future { promise in
            self.async(qos: qos) {
                do {
                    let value = try perform()
                    promise(.success(value))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
    
    /// Run a closure async on this queue, returning a Combine Future.
    func future<T>(
        qos: DispatchQoS = .unspecified,
        perform: @escaping () -> T
    ) -> Future<T, Never> {
        Future { promise in
            self.async(qos: qos) {
                let value = perform()
                promise(.success(value))
            }
        }
    }
}
