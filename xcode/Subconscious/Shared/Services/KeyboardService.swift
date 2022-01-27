//
//  KeyboardService.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/26/22.
//

import SwiftUI
import UIKit
import Combine

/// Enum representing the current state of the keyboard
enum KeyboardState {
    case willShow(
        size: CGSize,
        duration: Double
    )
    case didShow(size: CGSize)
    case didChangeFrame(size: CGSize)
    case willHide(
        size: CGSize,
        duration: Double
    )
    case didHide
}

/// Provides a publisher for keyboard state changes.
/// Typically used as a long-lived service.
final class KeyboardService {
    /// Publisher for keyboard state
    let state: CurrentValueSubject<KeyboardState, Never>

    init() {
        self.state = CurrentValueSubject(KeyboardState.didHide)
        //  NOTE: we add observers on init, but do not need to remove them.
        //  From Apple docs:
        //  https://developer.apple.com/documentation/foundation/notificationcenter/1413994-removeobserver
        //  If your app targets iOS 9.0 and later or macOS 10.11 and later,
        //  and you used addObserver(_:selector:name:object:), you do not
        //  need to unregister the observer. If you forget or are unable to
        //  remove the observer, the system cleans up the next time it
        //  would have posted to it.
        //  2022-01-26 Gordon Brander
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handle(keyboardWillShowNotification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handle(keyboardDidShowNotification:)),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handle(keyboardWillHideNotification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handle(keyboardDidHideNotification:)),
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handle(keyboardDidChangeFrameNotification:)),
            name: UIResponder.keyboardDidChangeFrameNotification,
            object: nil
        )
    }

    deinit {
        state.send(completion: .finished)
    }

    @objc private func handle(
        keyboardWillShowNotification notification: Notification
    ) {
        let info = notification.userInfo
        let frameEndKey = UIResponder.keyboardFrameEndUserInfoKey
        let durationKey =
            UIResponder.keyboardAnimationDurationUserInfoKey
        if
            let frame = info?[frameEndKey] as? CGRect,
            let duration = info?[durationKey] as? NSNumber
        {
            self.state.send(
                .willShow(
                    size: frame.size,
                    duration: duration.doubleValue
                )
            )
        }
    }

    @objc private func handle(
        keyboardDidShowNotification notification: Notification
    ) {
        let info = notification.userInfo
        let frameEndKey = UIResponder.keyboardFrameEndUserInfoKey
        if let frame = info?[frameEndKey] as? CGRect {
            self.state.send(.didShow(size: frame.size))
        }
    }

    @objc private func handle(
        keyboardWillHideNotification notification: Notification
    ) {
        let info = notification.userInfo
        let frameEndKey = UIResponder.keyboardFrameEndUserInfoKey
        let durationKey =
            UIResponder.keyboardAnimationDurationUserInfoKey
        if
            let frame = info?[frameEndKey] as? CGRect,
            let duration = info?[durationKey] as? NSNumber
        {
            self.state.send(
                .willHide(
                    size: frame.size,
                    duration: duration.doubleValue
                )
            )
        }
    }

    @objc private func handle(
        keyboardDidHideNotification notification: Notification
    ) {
        self.state.send(.didHide)
    }

    @objc private func handle(
        keyboardDidChangeFrameNotification notification: Notification
    ) {
        let info = notification.userInfo
        let frameEndKey = UIResponder.keyboardFrameEndUserInfoKey
        if let frame = info?[frameEndKey] as? CGRect {
            self.state.send(.didChangeFrame(size: frame.size))
        }
    }
}
