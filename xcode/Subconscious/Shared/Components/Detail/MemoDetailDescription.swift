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
}
