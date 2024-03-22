//
//  URLWithQueryParameters.swift
//  Subconscious
//
//  Created by Gordon Brander on 2/9/24.
//

import Foundation

extension URL {
    func withQueryParameters(_ params: [(String, String?)]) -> URL? {
        guard var components = URLComponents(
            url: self,
            resolvingAgainstBaseURL: false
        ) else {
            return nil
        }
        let queryParams = params.map({ (name, value) in
            URLQueryItem(name: name, value: value)
        })
        components.queryItems = queryParams
        return components.url
    }
}
