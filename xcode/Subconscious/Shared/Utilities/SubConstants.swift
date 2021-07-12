//
//  SubConstants.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/10/21.
//
import os

struct SubConstants {
    static let rdns = "com.subconscious.Subconscious"

    static let logger = Logger(
        subsystem: rdns,
        category: "main"
    )

    struct Duration {
        static let fast: Double = 0.128
        static let `default`: Double = 0.2
    }
}
