//
//  Prose.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/2/23.
//

import Foundation

enum Prose {}

extension Prose {
    static func chooseTitle(
        address: MemoAddress?,
        title: String?
    ) -> String? {
        if let title = title {
            return title
        }
        if let address = address {
            return address.slug.toTitle()
        }
        return nil
    }
    
    static func chooseTitle(
        address: MemoAddress?,
        title: String?,
        fallback: String
    ) -> String {
        chooseTitle(address: address, title: title) ?? fallback
    }
}
