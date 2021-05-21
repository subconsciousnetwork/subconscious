//
//  SearchService.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/20/21.
//

import Foundation
import Combine

struct SearchService {
    private let fileManager = FileManager.default
    
    func writeToIndex(_ url: URL) -> Future<Bool, Never> {
        Future({ promise in
            DispatchQueue.global(qos: .utility).async(execute: {
                print("SearchService.writeToIndex")
                promise(.success(true))
            })
        })
    }

    func removeFromIndex(_ url: URL) -> Future<Bool, Never> {
        Future({ promise in
            DispatchQueue.global(qos: .utility).async(execute: {
                print("SearchService.removeFromIndex")
                promise(.success(true))
            })
        })
    }
    
    func syncIndex() -> Future<Bool, Never> {
        Future({ promise in
            DispatchQueue.global(qos: .utility).async(execute: {
                let urls = fileManager
                    .listDocumentDirectoryContents()
                    .withPathExtension("subtext")
                
                // Left = Leader (files)
                let left = FileSync.readFileFingerprints(
                    with: fileManager,
                    urls: urls
                )
                // Right = Follower (search index)
                let right = FileSync.readFileFingerprints(
                    with: fileManager,
                    urls: urls
                )

                let changes = FileSync.calcChanges(
                    left: left,
                    right: right
                )
                
                for change in changes {
                    switch change.status {
                    // .leftOnly = create.
                    // .leftNewer = update.
                    // .rightNewer = ??? Follower should not be ahead. Leader wins.
                    // .conflict. Leader wins.
                    case .leftOnly, .leftNewer, .rightNewer, .conflict:
                        if let left = change.left {
                            _ = self.writeToIndex(left.url)
                        }
                    // .rightOnly = delete. Remove from search index
                    case .rightOnly:
                        if let right = change.right {
                            _ = self.removeFromIndex(right.url)
                        }
                    // .same = no change. Do nothing.
                    case .same:
                        break
                    }
                }
                
                promise(.success(true))
            })
        })
    }
}
