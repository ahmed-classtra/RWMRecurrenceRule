//
//  RWMRuleDailyIterator.swift
//  RWMRecurrenceRule
//
//  Created by Andrey Gordeev on 17/11/2018.
//

import Foundation

class RWMRuleDailyIterator: RWMRuleIterator {
    let exclusionDates: [Date]?

    init(exclusionDates: [Date]?) {
        self.exclusionDates = exclusionDates
    }

    func enumerateDates(with rule: RWMRecurrenceRule, startingFrom dtStart: Date?, enumerationStartDate: Date, calendar: Calendar, using block: EnumerationBlock) {
        // TODO - support BYSETPOS
        let start = dtStart ?? enumerationStartDate
        var result = start
        let interval = rule.interval ?? 1
        var count = 0
        var done = false
        var daysOfTheWeek: [Int]? = nil
        if let days = rule.daysOfTheWeek {
            daysOfTheWeek = days.map { $0.dayOfTheWeek.rawValue }
        }

        repeat {
            // Check if we are past the end date or we have returned the desired count
            if let stopDate = rule.recurrenceEnd?.endDate {
                if result > stopDate {
                    break
                }
            } else if let stopCount = rule.recurrenceEnd?.count {
                if count >= stopCount {
                    break
                }
            }

            // send current result
            var stop = false
            if doesDateMatchRule(date: result, rule: rule, calendar: calendar, daysOfTheWeek: daysOfTheWeek, dtStart: dtStart) && result >= enumerationStartDate {
                block(result, &stop)
            } else {
                count -= 1
            }
            if (stop) {
                break
            }

            var attempts = 0
            while attempts < 1000 {
                attempts += 1
                // Calculate the next date by adding "interval" days
                guard let date = calendar.date(byAdding: .day, value: interval, to: result) else {
                    // This shouldn't happen since we should always be able to add x days to the current result
                    done = true
                    break
                }
                result = date
                guard doesDateMatchRule(date: result, rule: rule, calendar: calendar, daysOfTheWeek: daysOfTheWeek, dtStart: dtStart) else { continue }
                count += 1
                break
            }
        } while !done
    }

    /// Return true if the given date matches the given rule and DTSTART.
    private func doesDateMatchRule(date: Date, rule: RWMRecurrenceRule, calendar: Calendar, daysOfTheWeek: [Int]?, dtStart: Date?) -> Bool {
        guard !isExclusionDate(date: date, calendar: calendar) else { return false }
        if date == dtStart {
            return true
        }

        return doesDateMatchMonthsOfYearRule(rule: rule, date: date, calendar: calendar)
            && doesDateMatchDaysOfMonthRule(rule: rule, date: date, calendar: calendar)
            && doesDateMatchDaysOfWeekRule(daysOfTheWeek: daysOfTheWeek, date: date, calendar: calendar)
    }

    private func doesDateMatchMonthsOfYearRule(rule: RWMRecurrenceRule, date: Date, calendar: Calendar) -> Bool {
        guard let months = rule.monthsOfTheYear else { return true }
        let rmonth = calendar.component(.month, from: date)
        return months.contains(rmonth)
    }

    private func doesDateMatchDaysOfMonthRule(rule: RWMRecurrenceRule, date: Date, calendar: Calendar) -> Bool {
        guard let monthDays = rule.daysOfTheMonth else { return true }
        var found = false
        let rday = calendar.component(.day, from: date)
        for monthDay in monthDays {
            if monthDay > 0 {
                if monthDay == rday {
                    found = true
                    break
                }
            } else {
                let range = calendar.range(of: .day, in: .month, for: date)!
                let lastDay = range.count
                if lastDay + monthDay + 1 == rday {
                    found = true
                    break
                }
            }
        }
        return found
    }

    private func doesDateMatchDaysOfWeekRule(daysOfTheWeek: [Int]?, date: Date, calendar: Calendar) -> Bool {
        guard let days = daysOfTheWeek else { return true }
        let rdow = calendar.component(.weekday, from: date)
        return days.contains(rdow)
    }
}
