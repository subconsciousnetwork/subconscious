//
//  CombineUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/14/21.
//

import Foundation
import Combine

struct CombineUtilities {
    static func throwable<T>(_ execute: @escaping () throws -> T) ->
        AnyPublisher<T, Error> {
        Future({ promise in
            do {
                let success = try execute()
                promise(.success(success))
            } catch {
                promise(.failure(error))
            }
        }).eraseToAnyPublisher()
    }
}
