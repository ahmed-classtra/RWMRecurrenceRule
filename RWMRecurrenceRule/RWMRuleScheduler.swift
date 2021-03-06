//
//  RWMRuleScheduler.swift
//  RWMRecurrenceRule
//
//  Created by Richard W Maddy on 5/17/18.
//  Copyright © 2018 Maddysoft. All rights reserved.
//

import Foundation

// NOTE - See https://icalendar.org/iCalendar-RFC-5545/3-3-10-recurrence-rule.html

/// The `RWMRuleScheduler` class is used in tadem with `RWMRecurrenceRule` to enumerate and test dates generated by
/// the recurrence rule.
public class RWMRuleScheduler {
    public enum Mode {
        case standard
        case eventKit
    }

    private let rule: RWMRecurrenceRule
    private let calendar: Calendar
    private let iterator: RWMRuleIterator

    public init(rule: RWMRecurrenceRule, timeZone: TimeZone? = nil, exclusionDates: [Date]? = nil, mode: Mode = .standard) {
        self.rule = rule

        var calendar = Calendar(identifier: .iso8601)
        calendar.firstWeekday = rule.firstDayOfTheWeek?.rawValue ?? 2
        calendar.timeZone = timeZone ?? calendar.timeZone
        self.calendar = calendar

        switch rule.frequency {
        case .daily:
            self.iterator = RWMRuleDailyIterator(exclusionDates: exclusionDates)
        case .weekly:
            self.iterator = RWMRuleWeeklyIterator(exclusionDates: exclusionDates, mode: mode)
        case .monthly:
            self.iterator = RWMRuleMonthlyIterator(exclusionDates: exclusionDates)
        case .yearly:
            self.iterator = RWMRuleYearlyIterator(exclusionDates: exclusionDates)
        }
    }

    /// Enumerates the dates of the recurrence rule.
    ///
    /// Some more here.
    ///
    /// - Parameters:
    ///   - rule: The recurrence rule.
    ///   - start: The initial `Date` (**DTSTART**) of the recurrence rule.
    ///   - block: A closure that is called for each date generated by the recurrence rule.
    ///   - date: The date.
    ///   - stop: The stop.
    public func enumerateDates(startingFrom start: Date, using block: EnumerationBlock) {
        iterator.enumerateDates(with: rule, startingFrom: start, calendar: calendar, using: block)
    }

    /// Determines if the date is one of the dates generated by the recurrence rule.
    ///
    /// - Parameters:
    ///   - date: The date to check for.
    ///   - rule: The recurrence rule generating the list of dates.
    ///   - start: The start date used as the basis of the recurrence rule.
    ///   - exact: `true` if the full date and time must match, `false` if the time is ignored.
    /// - Returns: `true` if `date` is one of the dates generated by `rule`, `false` if not.
    public func includes(date: Date, startingFrom start: Date, exact: Bool = false) -> Bool {
        var found = false

        enumerateDates(startingFrom: start) { (rdate, stop) in
            if let rdate = rdate {
                if (exact && rdate == date) || (!exact && Calendar.current.isDate(rdate, inSameDayAs: date)) {
                    found = true
                    stop = true
                } else if rdate > date {
                    stop = true
                }
            }
        }

        return found
    }

    /// Returns the next possible event date after the supplied date. If there are no recurrences after the date,
    /// the result is `nil`.
    ///
    /// - Parameters:
    ///   - date: The date to check for.
    ///   - start: The start date used as the basis of the recurrence rule.
    /// - Returns: The first date after `date` in the list of dates generated by `rule`. If `date` is after the last recurrence date, the result is `nil`.
    public func nextDate(after date: Date, startingFrom start: Date) -> Date? {
        var found: Date? = nil

        enumerateDates(startingFrom: start) { (rdate, stop) in
            if let rdate = rdate {
                if rdate > date {
                    stop = true
                    found = rdate
                }
            }
        }

        return found
    }
}
