//
//  StoreUtilities.swift
//  Subconscious
//
//  Created by Ben Follington on 3/11/2023.
//

import Foundation
import ObservableStore

extension Store where Model : ModelProtocol {
    /// Utility method to turn a store into a  ViewStore, intended for use in SwiftUI previews.
    func toViewStoreForSwiftUIPreview() -> ViewStore<Model> {
        return self.viewStore(get: { $0 }, tag: { $0 })
    }
}
