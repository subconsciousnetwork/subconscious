//
//  KeychainService.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 6/3/2024.
//

import Foundation
import KeychainSwift

actor KeychainService {
    private let keychain = KeychainSwift()

    func getApiKey() -> String? {
        return keychain.get("openAIKey")
    }

    func setApiKey(_ key: String) {
        keychain.set(key, forKey: "openAIKey")
    }
}
