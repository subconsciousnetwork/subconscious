//
//  Did.swift
//  Subconscious
//
//  Created by Ben Follington on 1/3/2023.
//

import Foundation

struct Did : Hashable, Identifiable, Codable {
    let did: String
    var id: String { did }
    
    // Approximate, based on https://www.w3.org/TR/did-core/#did-syntax
    static let regex = /^(did:[a-z0-9]{3}:[a-zA-Z0-9-_\.%:]+)$/
    
    init?(did: String) {
        guard let did = try? Self.regex.wholeMatch(in: did) else {
            return nil
        }
        
        self.did = String(did.1)
    }
}

extension Did: LosslessStringConvertible {
    var description: String { did }
    
    init?(_ description: String) {
        self.init(did: description)
    }
}
