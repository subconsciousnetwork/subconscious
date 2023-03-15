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
    
    /// Get address for description, if any.
    /// - Returns MemoAddress or nil
    var address: MemoAddress? {
        switch self {
        case .editor(let description):
            return description.address
        case .viewer(let description):
            return description.address
        }
    }
}
