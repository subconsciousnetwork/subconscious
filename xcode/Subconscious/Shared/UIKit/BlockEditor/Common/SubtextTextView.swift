//
//  SubtextTextView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 8/29/23.
//

import UIKit
import os

extension UIView {
    class SubtextTextStorage: NSTextStorage {
        private let backingStore = NSMutableAttributedString()
        private var dom = Subtext(markup: "")
        
        override var string: String {
            return backingStore.string
        }
        
        override func attributes(
            at location: Int,
            effectiveRange range: NSRangePointer?
        ) -> [NSAttributedString.Key : Any] {
            return backingStore.attributes(at: location, effectiveRange: range)
        }
        
        override func replaceCharacters(
            in range: NSRange,
            with str: String
        ) {
            beginEditing()
            backingStore.replaceCharacters(in: range, with: str)
            edited(
                .editedCharacters,
                range: range,
                changeInLength: (str as NSString).length - range.length
            )
            endEditing()
        }
        
        override func setAttributes(
            _ attrs: [NSAttributedString.Key : Any]?,
            range: NSRange
        ) {
            beginEditing()
            backingStore.setAttributes(attrs, range: range)
            edited(
                .editedAttributes,
                range: range,
                changeInLength: 0
            )
            endEditing()
        }
    }

    /// A subclass of UITextView that automatically renders Subtext
    /// as attributes on text storage.
    class SubtextTextView: UITextView, Identifiable, NSTextStorageDelegate {
        static let logger = Logger(
            subsystem: Config.default.rdns,
            category: "SubtextTextView"
        )
        
        var id = UUID()
        var renderer = SubtextAttributedStringRenderer()
        private(set) var dom = Subtext(markup: "")
        
        private let defaultTextContainerInset = UIEdgeInsets(
            top: AppTheme.unit2,
            left: AppTheme.padding,
            bottom: AppTheme.unit2,
            right: AppTheme.padding
        )
        
        override init(frame: CGRect, textContainer: NSTextContainer?) {
            super.init(frame: frame, textContainer: textContainer)
            // Automatically adjust font size based on system font size
            adjustsFontForContentSizeCategory = true
            font = .preferredFont(forTextStyle: .body)
            textContainerInset = defaultTextContainerInset
            self.textContainer.lineFragmentPadding = 0
            textStorage.delegate = self
            // !!!: Hack to trigger initial rendering of attributes
            // UITextView has a bug where a text view that has been created
            // with an empty string does not correctly render attributes until
            // given a non-empty string. This results in a jump triggered by
            // a change in intrinsic content size when the attributes are
            // first applied.
            //
            // After being rendered with a non-empty string, it works properly.
            // 2023-11-22 Gordon
            self.text = " "
            self.text = ""
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
            self.dom = renderer.renderAttributesOf(textStorage)
            Self.logger.debug(
                "SubtextTextView#\(self.id) Rendered Subtext attributes"
            )
        }
    }
}
