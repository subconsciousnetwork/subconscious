//
//  BlockCellProtocol.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/31/24.
//

import UIKit

/// A protocol offering shared functionality for cells.
/// We're taking a composition over inheritence approach to this.
protocol BlockCellProtocol: UICollectionViewCell {}

extension BlockCellProtocol {
    /// Set default theme for block cells
    @discardableResult
    func themeDefault() -> Self {
        self.contentView.backgroundColor = .accent.withAlphaComponent(0.1)
        return self
    }
}
