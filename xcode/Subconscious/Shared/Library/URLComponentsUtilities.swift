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
    func firstQueryItemWhere(name: String) -> URLQueryItem? {
        guard let items = queryItems else {
            return nil
        }
        return items.first(where: { item in item.name == name })
    }
}
