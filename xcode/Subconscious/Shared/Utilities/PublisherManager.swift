//
//  PublisherManager.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/10/21.
//

import Foundation
import Combine

/// Holds cancellables returned by Publisher until the publisher completes.
///
/// Combine Publishers return a Cancellable that will automatically cancel the Publisher if the
/// Cancellable falls out of scope. Since Publishers can take some time to complete, you often
/// want to hold on to the Cancellable reference until the publisher has completed.
///
/// PublisherManager takes care of the boilerplate of holding on to Cancellables, and helps
/// you avoid the memory leak footgun of accidentally strong-referencing self in the completion handler.
///
/// The intent is to instantiate a long-lived instance of PublisherManager to manage multiple Publishers.
///
/// Publisher Cancellables are stored in a map by UUID.
/// The UUID is returned by `PublisherManager.sink`
/// You can also cancel a publisher by calling `PublisherManager.cancel` with the UUID.
final class PublisherManager {
    /// Hashmap to store cancellables by ID
    private var cancellables: [UUID: AnyCancellable] = [:]

    /// Cancel a publisher by its id
    func cancel(id: UUID) {
        let value = cancellables.removeValue(forKey: id)
        value?.cancel()
    }
    
    /// Similar in concept to `Publisher.sink` except that it holds on to the cancellable reference
    /// until the cancellable is complete.
    /// Returns a UUID that may be used with `cancel` to cancel the publisher.
    @discardableResult func sink<T, E: Error> (
        publisher: AnyPublisher<T, E>,
        receiveValue: @escaping (T) -> Void
    ) -> UUID {
        // Create a UUID for the cancellable.
        // Store cancellable in dictionary by UUID.
        // Remove cancellable from dictionary upon effect completion.
        // This retains the effect pipeline for as long as it takes to complete
        // the effect, and then removes it, so we don't have a cancellables
        // memory leak.
        let id = UUID()
        let cancellable = publisher
            .sink(
                receiveCompletion: { [weak self] _ in
                    self?.cancellables.removeValue(forKey: id)
                },
                receiveValue: receiveValue
            )
        self.cancellables[id] = cancellable
        return id
    }
}
