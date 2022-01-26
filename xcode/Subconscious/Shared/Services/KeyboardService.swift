//
//  KeyboardService.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/26/22.
//

import SwiftUI
import UIKit

class KeyboardService {
    enum KeyboardState {
        case willShow
        case didShow
        case willHide
        case didHide
    }

    /// Current keyboard state
    var keyboardState = KeyboardState.didHide
    /// The height of the keyboard, before animation is complete.
    var keyboardSize: CGSize = .zero
    /// Duration of keyboard animation.
    var keyboardAnimationDuration: Double = 0

    init() {
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

    @objc private func handle(
        keyboardWillShowNotification notification: Notification
    ) {
        self.keyboardState = .willShow
        if let frame = notification.userInfo?[
            UIResponder.keyboardFrameEndUserInfoKey
        ] as? CGRect {
            self.keyboardSize = frame.size
        }
        if let duration = notification.userInfo?[
            UIResponder.keyboardAnimationDurationUserInfoKey
        ] as? Double {
            self.keyboardAnimationDuration = duration
        }
    }

    @objc private func handle(
        keyboardDidShowNotification notification: Notification
    ) {
        self.keyboardState = .didShow
        if
            let userInfo = notification.userInfo,
            let frame = userInfo[
                UIResponder.keyboardFrameEndUserInfoKey
            ] as? CGRect
        {
            self.keyboardSize = frame.size
        }
    }

    @objc private func handle(
        keyboardWillHideNotification notification: Notification
    ) {
        self.keyboardState = .willHide
        if let duration = notification.userInfo?[
            UIResponder.keyboardAnimationDurationUserInfoKey
        ] as? Double {
            self.keyboardAnimationDuration = duration
        }
    }

    @objc private func handle(
        keyboardDidHideNotification notification: Notification
    ) {
        self.keyboardState = .didHide
        self.keyboardSize = .zero
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
            self.keyboardSize = frame.size
        }
    }
}
