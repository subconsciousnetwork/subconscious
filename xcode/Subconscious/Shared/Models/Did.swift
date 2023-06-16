//
//  Did.swift
//  Subconscious
//
//  Created by Ben Follington on 1/3/2023.
//

import Foundation

public struct Did : Hashable, Identifiable, Codable {
    public let did: String
    public var id: String { did }
    
    // Approximate, based on
    // https://www.w3.org/TR/did-core/#did-syntax
    // https://w3c-ccg.github.io/did-method-key/
    private static let regex = /did:[a-z0-9]+:[a-zA-Z0-9_\-\.\%]+/
    
    public init?(did: String) {
        guard let did = try? Self.regex.wholeMatch(in: did) else {
            return nil
        }
        
        self.did = String(did.0)
    }
}

extension Did: LosslessStringConvertible {
    public var description: String { did }
    
    public init?(_ description: String) {
        self.init(did: description)
    }
}

extension String {
    func toDid() -> Did? {
        Did(self)
    }
}
