//
//  TextViewRepresentable.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 12/15/21.

import SwiftUI

/// A textview that grows to the height of its content
struct TextViewRepresentable: UIViewRepresentable {
    class Coordinator: NSObject, UITextViewDelegate {
        /// Is event happening during updateUIView?
        /// Used to avoid sending up events that would cause feedback cycles where an update triggers
        /// an event, which triggers an update, which triggers an event, etc.
        var isUIViewUpdating: Bool
        var representable: TextViewRepresentable

        init(_ representable: TextViewRepresentable) {
            self.isUIViewUpdating = false
            self.representable = representable
        }

        /// Handle changes to textview
        func textViewDidChange(_ view: UITextView) {
            // Return early if view is updating.
            guard !isUIViewUpdating else {
                return
            }
            if representable.text != view.text {
                representable.text = view.text
            }
        }

        /// Handle editing begin (focus)
        func textViewDidBeginEditing(_ textView: UITextView) {
            representable.isFocused = true
        }

        /// Handle editing end (blur)
        func textViewDidEndEditing(_ textView: UITextView) {
            representable.isFocused = false
        }
    }

    @Binding var text: String
    @Binding var isFocused: Bool
    var font: UIFont = UIFont.preferredFont(forTextStyle: .body)

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        // Remove text container inset
        view.textContainerInset = .zero
        // Remove that extra bit of inner padding.
        // Text in view should now be flush with view edge.
        // This puts you in full control of view padding.
        view.textContainer.lineFragmentPadding = 0
        // Make background transparent
        view.backgroundColor = .clear
        // Set font
        view.font = font
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        // Set updating flag on coordinator
        context.coordinator.isUIViewUpdating = true
        // Unset updating flag on coordator after this scope exits
        defer {
            context.coordinator.isUIViewUpdating = false
        }

        if view.text != self.text {
            // Save selected range (cursor position).
            let selectedRange = view.selectedRange
            view.text = self.text
            // Restore selected range (cursor position) after setting text.
            view.selectedRange = selectedRange
        }

        // Set firstResponder
        if isFocused != view.isFirstResponder {
            if isFocused {
                DispatchQueue.main.async {
                    view.becomeFirstResponder()
                }
            } else {
                DispatchQueue.main.async {
                    view.resignFirstResponder()
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
