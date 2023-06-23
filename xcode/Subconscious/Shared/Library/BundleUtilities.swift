//
//  BundleUtilities.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/26/22.
//

import Foundation

extension Bundle {
    /// Read a resource, returning a `Data`
    func read(resource: String, withExtension ext: String) throws -> Data {
        let url = try self.url(forResource: resource, withExtension: ext)
            .unwrap()
        return try Data(contentsOf: url)
    }
}

/// Extend Bundle to expose version helpers
extension Bundle {
    /// Get app version
    var version: String? {
        infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    /// Get app build version
    var buildVersion: String? {
        infoDictionary?["CFBundleVersion"] as? String
    }
}
