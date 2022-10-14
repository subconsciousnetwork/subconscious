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

struct OnThisDayGeist: Geist {
    private let database: DatabaseService

    init(database: DatabaseService) {
        self.database = database
    }
    
    func transformDate(date: Date, component: Calendar.Component, value: Int) -> Date? {
        guard let d = Calendar.current.date(byAdding: component, value: value, to: date) else {
            return nil
        }
        
        return d
    }
    
    func dateFromVariant(variant: OnThisDayVariant) -> (Date, Date)? {
        // Verbose but easy to extend, allows for custom definition of the time window rather than
        // locking us into a "day" being the only possible timespan.
        switch variant {
            case .aYearAgo:
                guard
                    let lower = transformDate(date: Date.now, component: Calendar.Component.year, value: -1),
                    let upper = transformDate(date: lower, component: Calendar.Component.day, value: 1)
                    else { return nil }
                return (lower, upper)
            case .sixMonthsAgo:
                guard
                    let lower = transformDate(date: Date.now, component: Calendar.Component.month, value: -6),
                    let upper = transformDate(date: lower, component: Calendar.Component.day, value: 1)
                    else { return nil }
                return (lower, upper)
            case .aMonthAgo:
                guard
                    let lower = transformDate(date: Date.now, component: Calendar.Component.month, value: -1),
                    let upper = transformDate(date: lower, component: Calendar.Component.day, value: 1)
                    else { return nil }
                return (lower, upper)
            case .inTheLastWeek:
                guard
                    let lower = transformDate(date: Date.now, component: Calendar.Component.day, value: -7),
                    let upper = transformDate(date: lower, component: Calendar.Component.day, value: 6)
                    else { return nil }
                return (lower, upper)
            case .inTheLastDay:
                guard
                    let lower = transformDate(date: Date.now, component: Calendar.Component.day, value: -1),
                    let upper = transformDate(date: lower, component: Calendar.Component.day, value: 1)
                    else { return nil }
                return (lower, upper)
        }
    }

    func ask(query: String) -> Story? {
        let variant = OnThisDayVariant.random()
        
        guard let (start, end) = dateFromVariant(variant: <#T##OnThisDayVariant#>) else {
            return nil
        }
       
        guard let entry = database.readRandomEntryInDateRange(startDate: start, endDate: end) else {
            return nil
        }
        
        return Story.onThisDay(StoryOnThisDay(entry: entry, timespan: variant))
    }
}

