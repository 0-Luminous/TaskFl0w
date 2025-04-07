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
}
