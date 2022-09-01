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
        .receive(on: DispatchQueue.main)
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
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
