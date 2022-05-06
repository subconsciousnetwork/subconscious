//
//  HeaderParser.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/3/22.
//

import Foundation

/// Parsers based on `Tape`
enum Parser {}

extension Parser {
    static func discardSpaces(_ tape: inout Tape) {
        while let next = tape.peek() {
            if next != " " {
                tape.start()
                return
            }
            tape.advance()
        }
    }

    static func discardLine(_ tape: inout Tape) {
        while !tape.isExhausted() {
            let curr = tape.consume()
            if curr == "\n" {
                tape.start()
                return
            }
        }
    }

    /// Parse an entire line of text, up to and including the next
    /// newline (if any).
    static func parseLine(
        _ tape: inout Tape
    ) -> Substring {
        tape.start()
        while !tape.isExhausted() {
            let curr = tape.consume()
            if curr.isNewline {
                return tape.cut()
            }
        }
        return tape.cut()
    }

    /// Parse all lines until tape is exhausted
    /// - Returns array of Substrings (lines)
    static func parseLines(
        _ tape: inout Tape,
        keepEnds: Bool = true
    ) -> [Substring] {
        var lines: [Substring] = []
        tape.start()
        while !tape.isExhausted() {
            var line = parseLine(&tape)
            // Remove newline ending if needed
            if !keepEnds && line.last != nil && line.last!.isNewline {
                line.removeLast()
            }
            lines.append(line)
        }
        return lines
    }

    /// If the next character is a newline, drops it and returns rest.
    /// Otherwise returns nil.
    /// - Returns Substring
    static func parseEmptyLine(
        _ tape: inout Tape
    ) -> Bool {
        let next = tape.peek()
        if next != nil && next!.isNewline {
            tape.advance()
            tape.start()
            return true
        }
        return false
    }
}
