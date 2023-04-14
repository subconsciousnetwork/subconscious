//
//  CombineUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 6/14/21.
//

import Foundation
import Combine

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
