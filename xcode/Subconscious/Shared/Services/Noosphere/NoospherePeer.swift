//
//  NoospherePeer.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/18/23.
//

import Foundation

extension Noosphere {
    /// Describes a sphere petname and identity at a specific version
    public struct Peer: Hashable, Codable {
        /// Petname assigned to sphere
        public var petname: Petname
        /// DID of sphere
        public var identity: Did
        /// Sphere version
        public var version: Cid?
    }
}
