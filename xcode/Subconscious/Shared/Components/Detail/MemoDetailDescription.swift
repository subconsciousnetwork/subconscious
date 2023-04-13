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
    var address: MemoAddress? {
        switch self {
        case .editor(let description):
            return description.address
        case .viewer(let description):
            return description.address
        case .profile(let description):
            guard let petname = Petname(petnames: description.spherePath) else {
                return nil
            }
            
            return Slashlink(petname: petname).toPublicMemoAddress()
        }
    }
}

extension MemoDetailDescription {
    /// Create a detail description from an address and additional data.
    /// Returns the best Memo Detail type for data provided.
    static func from(
        address: MemoAddress?,
        fallback: String,
        defaultAudience: Audience = .local
    ) -> Self {
        switch address {
        case .local(let slug):
            return .editor(
                MemoEditorDetailDescription(
                    address: slug.toLocalMemoAddress(),
                    fallback: fallback,
                    defaultAudience: .local
                )
            )
        case .public(let slashlink) where slashlink.petname == nil:
            return .editor(
                MemoEditorDetailDescription(
                    address: slashlink.toPublicMemoAddress(),
                    fallback: fallback,
                    defaultAudience: .public
                )
            )
        case .public(let slashlink):
            return .viewer(
                MemoViewerDetailDescription(
                    address: slashlink.toPublicMemoAddress()
                )
            )
        case .none:
            return .editor(
                MemoEditorDetailDescription(
                    fallback: fallback,
                    defaultAudience: defaultAudience
                )
            )
        }
    }
}
