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
}

extension Date {
    func formattedForTodoList() -> String {
        return DateFormatter.todoDateFormatter.string(from: self)
    }
}
