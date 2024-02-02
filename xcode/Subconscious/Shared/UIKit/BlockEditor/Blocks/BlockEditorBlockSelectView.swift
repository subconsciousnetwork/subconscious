//
//  BlockEditorBlockSelectView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 9/15/23.
//

import UIKit

extension BlockEditor {
    /// A rounded rect view that is used as the background of BlockEditor blocks
    /// when in block select mode.
    class BlockSelectView: UIView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            layer.cornerRadius = AppTheme.cornerRadius
            self.update(BlockSelectionModel.normal)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @discardableResult
        func update(
            _ state: BlockEditor.BlockSelectionModel
        ) -> Self {
            UIView.animate(withDuration: Duration.fast) {
                switch (
                    state.isEditing,
                    state.isBlockSelectMode,
                    state.isBlockSelected
                ) {
                case (true, false, _):
                    self.backgroundColor = .quaternarySystemFill
                    self.alpha = 1
                    return
                case (false, true, true):
                    self.backgroundColor = .accent.withAlphaComponent(0.1)
                    self.alpha = 1
                    return
                default:
                    self.backgroundColor = .clear
                    self.alpha = 0
                    return
                }
            }
            return self
        }

        @discardableResult
        func layoutDefault() -> Self {
            self.layoutBlock(
                edges: UIEdgeInsets(
                    top: 1,
                    left: AppTheme.unit,
                    bottom: 1,
                    right: AppTheme.unit
                )
            )
        }
    }
}
