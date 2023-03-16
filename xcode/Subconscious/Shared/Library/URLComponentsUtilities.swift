//
//  URLComponentsUtilities.swift
//  Subconscious
//
//  Created by Gordon Brander on 4/21/22.
//

import Foundation

extension URLComponents {
    /// Get the first query string item with the given name.
    /// - Returns: first query item where name matches name given, or nil
    func firstQueryValueWhere(name: String) -> String? {
        guard let items = queryItems else {
            return nil
        }
        return items.first(where: { item in item.name == name })?.value
    }
}
