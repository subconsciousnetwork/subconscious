//
//  SubtextTextView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 8/29/23.
//

import UIKit
import os

extension UIView {
    /// A subclass of UITextView that automatically renders Subtext
    /// as attributes on text storage.
    class SubtextTextView: UITextView, Identifiable, NSTextStorageDelegate {
        var id = UUID()
        var renderer = SubtextAttributedStringRenderer()
        lazy var logger = Logger(
            subsystem: Config.default.rdns,
            category: "SubtextTextView#\(id)"
        )
        
        override init(frame: CGRect, textContainer: NSTextContainer?) {
            super.init(frame: frame, textContainer: textContainer)
            textStorage.delegate = self
            
            // Automatically adjust font size based on system font size
            adjustsFontForContentSizeCategory = true
            textContainerInset = UIEdgeInsets(
                top: 8,
                left: 16,
                bottom: 8,
                right: 16
            )
            font = .preferredFont(forTextStyle: .body)
        }
                
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        /// NSTextStorageDelegate method
        /// Handle markup rendering, just before processEditing is fired.
        /// It is important that we render markup in `willProcessEditing`
        /// because it happens BEFORE font substitution. Rendering before font
        /// substitution gives the OS a chance to replace fonts for things like
        /// Emoji or Unicode characters when your font does not support them.
        /// See:
        /// https://github.com/gordonbrander/subconscious/wiki/nstextstorage-font-substitution-and-missing-text
        ///
        /// 2022-03-17 Gordon Brander
        func textStorage(
          _ textStorage: NSTextStorage,
          willProcessEditing: NSTextStorage.EditActions,
          range: NSRange,
          changeInLength: Int
        ) {
            renderer.renderAttributesOf(textStorage)
            logger.debug("Rendered Subtext attributes")
        }
    }
}
