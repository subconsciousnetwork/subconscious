//
//  Sphere+Link.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/4/23.
//

import Foundation

extension SphereProtocol {
    /// Resolve a slashlink to an absolute `Link`
    func resolveLink(slashlink: Slashlink) async throws -> Link {
        try await self.resolve(slashlink: slashlink).toLink().unwrap()
    }
}
