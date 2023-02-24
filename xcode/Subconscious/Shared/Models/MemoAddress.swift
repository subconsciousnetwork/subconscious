//
//  MemoAddress.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/9/23.
//

import Foundation

enum MemoAddress: Hashable, Codable {
    case local(Slug)
    case `public`(Slug)
    
    var slug: Slug {
        switch self {
        case .local(let slug):
            return slug
        case .public(let slug):
            return slug
        }
    }
}

extension MemoAddress: LosslessStringConvertible, Identifiable {
    /// An address is considered to be any two strings separated by `::`
    private static let addressRegex = /(.+)::(.+)/
    
    /// Initialize from a string
    init?(_ description: String) {
        guard
            let match = try? Self.addressRegex.wholeMatch(in: description)
        else {
            return nil
        }
        guard let audience = Audience(rawValue: String(match.1)) else {
            return nil
        }
        guard let slug = Slug(String(match.2)) else {
            return nil
        }
        switch audience {
        case .local:
            self = .local(slug)
        case .public:
            self = .public(slug)
        }
    }
    
    var description: String {
        switch self {
        case .local(let slug):
            return "local::\(slug)"
        case .public(let slug):
            return "public::\(slug)"
        }
    }
    
    var id: String { description }
}

extension MemoAddress {
    func toEntryLink(title: String? = nil) -> EntryLink {
        EntryLink(address: self, title: title)
    }
}

extension MemoAddress {
    func toLocalMemoAddress() -> Self {
        .local(slug)
    }
}

extension MemoAddress {
    func toPublicMemoAddress() -> Self {
        .public(slug)
    }
}

extension MemoAddress {
    // TODO: in future we will need to add an argument for the default petname
    // when converting from local to public.
    func withAudience(_ audience: Audience) -> Self {
        switch audience {
        case .local:
            return .local(slug)
        case .public:
            return .public(slug)
        }
    }
}

extension MemoAddress {
    func isLocal() -> Bool {
        switch self {
        case .local:
            return true
        default:
            return false
        }
    }
}

extension MemoAddress {
    func isPublic() -> Bool {
        switch self {
        case .public:
            return true
        default:
            return false
        }
    }
}

extension Slug {
    func toLocalMemoAddress() -> MemoAddress {
        .local(self)
    }
    
    func toPublicMemoAddress() -> MemoAddress {
        .public(self)
    }
}

extension String {
    /// Parse MemoAddress from string
    /// - Returns MemoAddress, if parse is successful, otherwise nil.
    func toMemoAddress() -> MemoAddress? {
        MemoAddress(self)
    }
}

extension MemoAddress {
    func toAudience() -> Audience {
        switch self {
        case .local:
            return .local
        case .public:
            return .public
        }
    }
}

extension EntryLink {
    init?(title: String, audience: Audience) {
        guard let slug = Slug(formatting: title) else {
            return nil
        }
        switch audience {
        case .local:
            self.init(address: MemoAddress.local(slug), title: title)
            return
        case .public:
            self.init(address: MemoAddress.public(slug), title: title)
            return
        }
    }
}
