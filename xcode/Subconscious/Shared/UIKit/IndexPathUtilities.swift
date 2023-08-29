//
//  IndexPathHelpers.swift
//  BlockEditor
//
//  Created by Gordon Brander on 8/4/23.
//

import Foundation

extension IndexPath {
    init(row: Int) {
        self.init(row: row, section: 0)
    }
}
