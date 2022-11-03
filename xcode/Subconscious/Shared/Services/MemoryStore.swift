//
//  MockStore.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/3/22.
//

import Foundation

enum MemoryStoreError: Error {
    case doesNotExist
}

final class MemoryStoreStorage {
    var data: [String: Data] = [:]
}

/// An in-memory store that conforms to StoreProtocol
/// Useful for testing.
struct MemoryStore: StoreProtocol {
    private var storage = MemoryStoreStorage()

    func read(_ key: String) throws -> Data {
        guard let value = storage.data[key] else {
            throw MemoryStoreError.doesNotExist
        }
        return value
    }
    
    func write(_ key: String, value: Data) throws {
        storage.data[key] = value
    }
    
    func remove(_ key: String) throws {
        self.storage.data.removeValue(forKey: key)
    }
    
    func list() throws -> [String] {
        Array(storage.data.keys)
    }

    func save() throws {
        
    }
}
