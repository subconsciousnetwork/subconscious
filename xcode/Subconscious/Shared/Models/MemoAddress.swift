//
//  MemoAddress.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/9/23.
//
import SwiftUI

enum MemoAddress: Hashable, Codable {
    case local(Slug)
    case `public`(Slashlink)
    
    var slug: Slug {
        switch self {
        case .local(let slug):
            return slug
        case .public(let slashlink):
            return slashlink.toSlug()
        }
    }
}

extension MemoAddress: LosslessStringConvertible, Identifiable, Comparable {
    /// An address is considered to be any two strings separated by `::`
    private static let addressRegex = /(.+)::(.+)/
    
    /// Initialize from a string
    init?(_ description: String) {
        guard let match = try? Self.addressRegex.wholeMatch(
            in: description
        ) else {
            return nil
        }
        guard let audience = Audience(rawValue: String(match.1)) else {
            return nil
        }
        switch audience {
        case .local:
            guard let slashlink = Slashlink(String(match.2)) else {
                return nil
            }
            // Local addresses must not include petnames
            guard slashlink.peer == nil else {
                return nil
            }
            self = .local(slashlink.toSlug())
        case .public:
            guard let slashlink = Slashlink(String(match.2)) else {
                return nil
            }
            self = .public(slashlink)
        }
    }
    
    var description: String {
        switch self {
        case .local(let slug):
            return "local::\(slug.toSlashlink())"
        case .public(let slashlink):
            return "public::\(slashlink)"
        }
    }
    
    var id: String { description }
    
    /// Compare addresses by alpha
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.id < rhs.id
    }
}

extension MemoAddress {
    /// Does this address point to content in one of our address spaces?
    /// - Returns true if local or sphere content in our own sphere, false otherwise.
    var isOurs: Bool {
        switch self {
        case .local:
            return true
        case .public(let slashlink) where slashlink.peer == nil:
            return true
        case .public:
            return false
        }
    }
}

extension MemoAddress {
    func toSlashlink() -> Slashlink {
        switch self {
        case .local(let slug):
            return slug.toSlashlink()
        case .public(let slashlink):
            return slashlink
        }
    }
}

extension MemoAddress {
    func toSlug() -> Slug {
        switch self {
        case .local(let slug):
            return slug
        case .public(let slashlink):
            return slashlink.toSlug()
        }
    }
    
    var isProfile: Bool {
        self.slug.isProfile
    }
    
    var isOurProfile: Bool {
        self.isOurs && self.isProfile
    }
    
    var petname: Petname? {
        switch self {
        case .local(_):
            return .none
        case .public(let slashlink):
            return slashlink.peer
        }
    }
}

extension MemoAddress {
    func toEntryLink(title: String? = nil) -> EntryLink {
        EntryLink(address: self, title: title)
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
        .public(Slashlink(slug: self))
    }
    
    func toMemoAddress(_ audience: Audience) -> MemoAddress {
        switch audience {
        case .local:
            return .local(self)
        case .public:
            return .public(self.toSlashlink())
        }
    }
}

extension Slashlink {
    func toLocalMemoAddress() -> MemoAddress {
        MemoAddress.local(self.toSlug())
    }
    
    func toPublicMemoAddress() -> MemoAddress {
        MemoAddress.public(self)
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

extension MemoAddress {
    func withAudience(_ audience: Audience) -> Self {
        switch audience {
        case .local:
            return slug.toLocalMemoAddress()
        case .public:
            return slug.toPublicMemoAddress()
        }
    }
}

extension Image {
    init(_ address: MemoAddress) {
        switch address {
        case .local:
            self.init(systemName: "circle.dashed")
        case .public:
            self.init(systemName: "network")
        }
    }
}
