//
//  MemoAddress.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/9/23.
//

import Foundation

/// An ID that is a combination of slug and local draft flag.
struct MemoAddress: Hashable, CustomStringConvertible, Codable {
    let slug: Slug
    let audience: Audience
    
    var description: String {
        return "\(audience.rawValue)::\(slug)"
    }
    
    init(slug: Slug, audience: Audience) {
        self.slug = slug
        self.audience = audience
    }
    
    init?(formatting title: String, audience: Audience) {
        guard let slug = Slug(formatting: title) else {
            return nil
        }
        self.slug = slug
        self.audience = audience
    }
    
    func withAudience(_ audience: Audience) -> Self {
        MemoAddress(slug: self.slug, audience: audience)
    }
}

extension String {
    func toMemoAddress(audience: Audience) -> MemoAddress? {
        MemoAddress(formatting: self, audience: audience)
    }
}

extension Slug {
    func toMemoAddress(audience: Audience) -> MemoAddress {
        MemoAddress(slug: self, audience: audience)
    }
}
