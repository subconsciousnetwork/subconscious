//  SubConstants.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/10/21.
//
import SwiftUI
import os

struct SubConstants {
    static let rdns = "com.subconscious.Subconscious"

    static let logger = Logger(
        subsystem: rdns,
        category: "main"
    )

    struct Theme {
        static let cornerRadius: Double = 12
    }

    struct Duration {
        static let fast: Double = 0.128
        static let `default`: Double = 0.2
    }
}

extension Shadow {
    static let lightShadow = Shadow(
        color: Color.black.opacity(0.05),
        radius: 2,
        x: 0,
        y: 0
    )
}
