//
//  MockStore.swift
//  Subconscious
//
//  Created by Gordon Brander on 11/3/22.
//

import Foundation

/// A struct containing data needed to simulate our store interface
struct MemoryStoreData {
    var data: Data
    var created: Date = Date.now
    var modified: Date = Date.now
    var size: Int { data.count }
}

enum MemoryStoreError: Error {
    case doesNotExist(String)
}

final class MemoryStoreStorage {
    var data: [String: MemoryStoreData] = [:]
}

/// An in-memory store that conforms to StoreProtocol
/// Useful for testing.
struct MemoryStore: StoreProtocol {
    private var storage = MemoryStoreStorage()

    func read(_ key: String) -> Data? {
        guard let value = storage.data[key] else {
            return nil
        }
        return value.data
    }
    
    func write(_ key: String, value data: Data) throws {
        guard var value = storage.data[key] else {
            storage.data[key] = MemoryStoreData(data: data)
            return
        }
        value.data = data
        value.modified = Date.now
        storage.data[key] = value
    }
    
    func remove(_ key: String) throws {
        self.storage.data.removeValue(forKey: key)
    }
    
    func info(_ key: String) -> FileInfo? {
        guard let value = storage.data[key] else {
            return nil
        }
        return FileInfo(
            created: value.created,
            modified: value.modified,
            size: value.size
        )
    }
    
    func list() -> [String] {
        Array(storage.data.keys)
    }

    func save() throws {
        
    }
}
