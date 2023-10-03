//
//  MockErrorLoggingService.swift
//  SubconsciousTests
//
//  Created by Gordon Brander on 10/3/23.
//

import Foundation
@testable import Subconscious

class MockErrorLoggingService: ErrorLoggingServiceProtocol {
    private(set) var errors: [Error] = []

    func capture(error: Error) {
        errors.append(error)
    }
}
