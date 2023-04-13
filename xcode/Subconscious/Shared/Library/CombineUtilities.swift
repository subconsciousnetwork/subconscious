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

extension Future where Failure == Error {
    /// Initialize a future by immediately performing a throwing closure.
    convenience init(_ perform: @escaping () throws -> Output) {
        self.init { promise in
            do {
                let value = try perform()
                promise(.success(value))
            } catch {
                promise(.failure(error))
            }
        }
    }
}

extension Future where Failure == Never {
    /// Initialize a future by immediately performing a throwing closure.
    convenience init(_ perform: @escaping () -> Output) {
        self.init { promise in
            let value = perform()
            promise(.success(value))
        }
    }
}

extension Publisher {
    /// Recover from a failure.
    /// Similar to `catch` but allows you to map an `Error` to an `Output`,
    /// without having to wrap in a publisher.
    func recover(
        _ transform: @escaping (Error) -> Output
    ) -> Publishers.Catch<Self, Just<Output>> {
        self.catch({ error in
            Just(transform(error))
        })
    }
}
