//
//  CustomLogStringConvertible.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 9/8/22.
//

import Foundation
import os

/// A protocol like CustomDebugStringConvertable, but intended to generate
/// short one-line descriptives suitable for logging.
public protocol CustomLogStringConvertible {
    var logDescription: String { get }
}

extension String {
    public static func loggable<T>(_ type: T) -> String
    where T: CustomLogStringConvertible
    {
        type.logDescription
    }

    public static func loggable<T>(_ type: T) -> String
    where T: CustomDebugStringConvertible
    {
        type.debugDescription
    }

    public static func loggable<T>(_ type: T) -> String {
        String(describing: type)
    }
}
