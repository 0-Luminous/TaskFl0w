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

    // Добавляем форматы для китайской версии (упрощенный китайский)
    static let todoDateFormatterZh: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy/MM/dd"
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        return formatter
    }()

    static let clockDateFormatterZh: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        return formatter
    }()

    static let weekdayFormatterZh: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "zh_Hans_CN")
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

    // Китайские методы форматирования
    func formattedForTodoListZh() -> String {
        return DateFormatter.todoDateFormatterZh.string(from: self)
    }

    func formattedForClockDateZh() -> String {
        return DateFormatter.clockDateFormatterZh.string(from: self)
    }

    func formattedWeekdayZh() -> String {
        return DateFormatter.weekdayFormatterZh.string(from: self)
    }

    // Локализованные форматы дат и дней недели
    func formattedForTodoListLocalized() -> String {
        switch Locale.current.languageCode {
        case "ru":
            return formattedForTodoList()
        case "zh":
            return formattedForTodoListZh()
        default:
            return formattedForTodoListEn()
        }
    }

    func formattedForClockDateLocalized() -> String {
        switch Locale.current.languageCode {
        case "ru":
            return formattedForClockDate()
        case "zh":
            return formattedForClockDateZh()
        default:
            return formattedForClockDateEn()
        }
    }

    func formattedWeekdayLocalized() -> String {
        switch Locale.current.languageCode {
        case "ru":
            return formattedWeekday()
        case "zh":
            return formattedWeekdayZh()
        default:
            return formattedWeekdayEn()
        }
    }
}
