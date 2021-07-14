//
//  CombineUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/14/21.
//

import Foundation
import Combine

struct CombineUtilities {
    /// Run a throwing function asyncronously on the global DispatchQueue.
    static func async<T>(
        qos: DispatchQoS.QoSClass = .default,
        execute: @escaping () throws -> T
    ) -> AnyPublisher<T, Error> {
        Future({ promise in
            DispatchQueue.global(qos: qos).async(execute: {
                do {
                    let success = try execute()
                    promise(.success(success))
                } catch {
                    promise(.failure(error))
                }
            })
        }).eraseToAnyPublisher()
    }
}
