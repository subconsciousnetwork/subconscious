//
//  Detail.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/15/23.
//

import Foundation

/// An enum of possible detail types.
/// Used for the navigation stack.
enum MemoDetailDescription: Hashable {
    case editor(MemoEditorDetailDescription)
    case viewer(MemoViewerDetailDescription)
    case profile(UserProfileDetailDescription)
    
    /// Get address for description, if any.
    /// - Returns MemoAddress or nil
    var address: Slashlink? {
        switch self {
        case .editor(let description):
            return description.address
        case .viewer(let description):
            return description.address
        case .profile(let description):
            return description.address
        }
    }
}

extension MemoDetailDescription {
    /// Create a detail description from an address and additional data.
    /// Returns the best Memo Detail type for data provided.
    static func from(
        address: Slashlink?,
        fallback: String,
        defaultAudience: Audience = .local
    ) -> Self {
        guard let address = address else {
            return .editor(
                MemoEditorDetailDescription(
                    fallback: fallback,
                    defaultAudience: defaultAudience
                )
            )
        }
        guard address.isOurs else {
            return .viewer(
                MemoViewerDetailDescription(address: address)
            )
        }
        return .editor(
            MemoEditorDetailDescription(
                address: address,
                fallback: fallback,
                defaultAudience: .public
            )
        )
    }
}
