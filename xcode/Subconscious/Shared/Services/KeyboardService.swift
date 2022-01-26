//
//  KeyboardService.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/26/22.
//

import SwiftUI
import UIKit
import Combine

/// Provides a publisher for keyboard state changes.
/// Typically used as a long-lived service.
final class KeyboardService {
    enum KeyboardState {
        case willShow(size: CGSize)
        case didShow(size: CGSize)
        case willHide(size: CGSize)
        case didHide(size: CGSize)
        case didChangeFrame(size: CGSize)
    }

    /// Publisher for keyboard state
    let state: CurrentValueSubject<KeyboardState, Never>

    init() {
        self.state = CurrentValueSubject(.didHide(size: .zero))
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
        if let frame = notification.userInfo?[
            UIResponder.keyboardFrameEndUserInfoKey
        ] as? CGRect {
            self.state.send(.willShow(size: frame.size))
        }
    }

    @objc private func handle(
        keyboardDidShowNotification notification: Notification
    ) {
        if
            let userInfo = notification.userInfo,
            let frame = userInfo[
                UIResponder.keyboardFrameEndUserInfoKey
            ] as? CGRect
        {
            self.state.send(.didShow(size: frame.size))
        }
    }

    @objc private func handle(
        keyboardWillHideNotification notification: Notification
    ) {
        self.state.send(.willHide(size: .zero))
    }

    @objc private func handle(
        keyboardDidHideNotification notification: Notification
    ) {
        self.state.send(.didHide(size: .zero))
    }

    @objc private func handle(
        keyboardDidChangeFrameNotification notification: Notification
    ) {
        if
            let userInfo = notification.userInfo,
            let frame = userInfo[
                UIResponder.keyboardFrameEndUserInfoKey
            ] as? CGRect
        {
            self.state.send(.didChangeFrame(size: frame.size))
        }
    }
}
