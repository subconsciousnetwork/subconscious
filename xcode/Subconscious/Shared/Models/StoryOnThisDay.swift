//
//  StoryOnThisDay.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 30/9/2022.
//

import Foundation

/// "on this day" story model
struct StoryOnThisDay: Hashable, Identifiable, CustomStringConvertible {
    var id = UUID()
    var entry: EntryStub
    var timespan: OnThisDayVariant

    var description: String {
        "\(entry) posted \(timespan) ago"
    }
}
