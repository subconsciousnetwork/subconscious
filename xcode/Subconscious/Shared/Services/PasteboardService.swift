//
//  PasteboardService.swift
//  Subconscious
//
//  Created by Gordon Brander on 4/7/23.
//
//  Service wrapper around iOS pasteboard allowing for mocking

import SwiftUI

/// Exposes a minimal API surface to the pasteboard.
/// Just the parts we use here.
protocol PasteboardProtocol {
    var string: String? { get nonmutating set }
}

/// Implement PasteboardProtocol
extension UIPasteboard: PasteboardProtocol {}
