//
//  UICollectionViewHelpers.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/21/23.
//

import UIKit

extension UICollectionView {
    static func plainList(
        frame: CGRect
    ) -> UICollectionView {
        var config = UICollectionLayoutListConfiguration(appearance: .plain)
        config.showsSeparators = false
        let layout = UICollectionViewCompositionalLayout.list(using: config)

        return UICollectionView(
            frame: frame,
            collectionViewLayout: layout
        )
    }
}
