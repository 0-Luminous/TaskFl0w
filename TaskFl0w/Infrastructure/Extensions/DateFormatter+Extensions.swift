//
//  DateFormatter+Extensions.swift
//  ToDoList
//
//  Created by Yan on 25/3/25.
//

import Foundation

extension DateFormatter {
    static let todoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter
    }()
    
    static let clockDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()
    
    static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()

    // Добавляем форматы для английской версии в британском стиле
    static let todoDateFormatterEn: DateFormatter = {
        let formatter = DateFormatter()
        // британский стиль дат для списка задач
        formatter.dateFormat = "dd/MM/yy"
        formatter.locale = Locale(identifier: "en_GB")
        return formatter
    }()

    static let clockDateFormatterEn: DateFormatter = {
        let formatter = DateFormatter()
        // полный формат даты с месяцем словом (британский)
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "en_GB")
        return formatter
    }()

    static let weekdayFormatterEn: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "en_GB")
        return formatter
    }()
}

extension Date {
    func formattedForTodoList() -> String {
        return DateFormatter.todoDateFormatter.string(from: self)
    }
    
    func formattedForClockDate() -> String {
        return DateFormatter.clockDateFormatter.string(from: self)
    }
    
    func formattedWeekday() -> String {
        return DateFormatter.weekdayFormatter.string(from: self).capitalized
    }

    func formattedForTodoListEn() -> String {
        return DateFormatter.todoDateFormatterEn.string(from: self)
    }

    func formattedForClockDateEn() -> String {
        return DateFormatter.clockDateFormatterEn.string(from: self)
    }

    func formattedWeekdayEn() -> String {
        return DateFormatter.weekdayFormatterEn.string(from: self).capitalized
    }

    // Локализованные форматы дат и дней недели
    func formattedForTodoListLocalized() -> String {
        if Locale.current.languageCode == "ru" {
            return formattedForTodoList()
        } else {
            return formattedForTodoListEn()
        }
    }

    func formattedForClockDateLocalized() -> String {
        if Locale.current.languageCode == "ru" {
            return formattedForClockDate()
        } else {
            return formattedForClockDateEn()
        }
    }

    func formattedWeekdayLocalized() -> String {
        if Locale.current.languageCode == "ru" {
            return formattedWeekday()
        } else {
            return formattedWeekdayEn()
        }
    }
}
