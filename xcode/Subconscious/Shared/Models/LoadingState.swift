//
//  NetworkResourceState.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/6/23.
//

import Foundation

enum LoadingState: Hashable, Codable {
    case loading
    case loaded
    case notFound
}
