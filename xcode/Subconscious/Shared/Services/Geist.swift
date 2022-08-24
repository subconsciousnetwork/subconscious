//
//  Geist.swift
//  Subconscious
//
//  Created by Gordon Brander on 8/24/22.
//

import Foundation

protocol Geist {
    func ask(query: String) -> Story?
}
