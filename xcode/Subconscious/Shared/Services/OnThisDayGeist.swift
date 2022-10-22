//
//  OnThisDayGeist.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 30/9/2022.
//

import Foundation


enum OnThisDayVariant: CaseIterable {
    case inTheLastDay
    case inTheLastWeek
    case aYearAgo
    case sixMonthsAgo
    case aMonthAgo
    
    static func random() -> OnThisDayVariant {
        // https://stackoverflow.com/questions/63189870/return-a-random-case-from-an-enum-in-swift
        return allCases.randomElement()!
    }
}

struct DateRange: Hashable {
    var beginning: Date
    var end: Date
}

struct OnThisDayGeist: Geist {
    private let database: DatabaseService

    init(database: DatabaseService) {
        self.database = database
    }
    
    func addTo(date: Date, component: Calendar.Component, value: Int) -> Date? {
        guard let d = Calendar.current.date(byAdding: component, value: value, to: date) else {
            return nil
        }
        
        return d
    }
    
    func dateFromVariant(variant: OnThisDayVariant) -> DateRange? {
        // Verbose but easy to extend, allows for custom definition of the time window rather than
        // locking us into a "day" being the only possible timespan.
        switch variant {
            case .aYearAgo:
                guard
                    let lower = addTo(date: Date.now, component: Calendar.Component.year, value: -1),
                    let upper = addTo(date: lower, component: Calendar.Component.day, value: 1)
                    else { return nil }
                return DateRange(beginning: lower, end: upper)
            case .sixMonthsAgo:
                guard
                    let lower = addTo(date: Date.now, component: Calendar.Component.month, value: -6),
                    let upper = addTo(date: lower, component: Calendar.Component.day, value: 1)
                    else { return nil }
                return DateRange(beginning: lower, end: upper)
            case .aMonthAgo:
                guard
                    let lower = addTo(date: Date.now, component: Calendar.Component.month, value: -1),
                    let upper = addTo(date: lower, component: Calendar.Component.day, value: 1)
                    else { return nil }
                return DateRange(beginning: lower, end: upper)
            case .inTheLastWeek:
                guard
                    let lower = addTo(date: Date.now, component: Calendar.Component.day, value: -7),
                    let upper = addTo(date: lower, component: Calendar.Component.day, value: 6)
                    else { return nil }
                return DateRange(beginning: lower, end: upper)
            case .inTheLastDay:
                guard
                    let lower = addTo(date: Date.now, component: Calendar.Component.day, value: -1)
                    else { return nil }
                return DateRange(beginning: lower, end: Date.now)
        }
    }

    func ask(query: String) -> Story? {
        // Check all possible variant cases and keep the ones that actually yield entries
        let storyPool = OnThisDayVariant.allCases
            .map({ variant -> Story? in
                guard let range = dateFromVariant(variant: variant) else {
                    return nil
                }
                
                guard let entry = database.readRandomEntryInDateRange(startDate: range.beginning, endDate: range.end) else {
                    return nil
                }
                
                return Story.onThisDay(StoryOnThisDay(entry: entry, timespan: variant))
            })
            .compactMap({ $0 }) // Filter out nil cases
        
        return storyPool.randomElement()
    }
}

