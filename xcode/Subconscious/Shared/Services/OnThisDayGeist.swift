//
//  OnThisDayGeist.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 30/9/2022.
//

import Foundation

struct OnThisDayGeist: Geist {
    private let database: DatabaseService

    init(database: DatabaseService) {
        self.database = database
    }

    func ask(query: String) -> Story? {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date.now) else { return nil }
        guard let entry = database.readRandomEntryInDateRange(startDate: yesterday, endDate: Date.now) else {
            return nil
        }
        
        return Story.onThisDay(StoryOnThisDay(entry: entry, timespan: "6mo"))
    }
}

