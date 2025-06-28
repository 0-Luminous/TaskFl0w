//
//  ToDoItem.swift
//  ToDoList
//
//  Created by Yan on 19/3/25.
//
import Foundation

struct ToDoItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var date: Date
    var isCompleted: Bool
    var categoryID: UUID?
    var categoryName: String?
    var priority: TaskPriority
    var deadline: Date? // Добавляем поле крайнего срока

    init(
        id: UUID = UUID(), title: String, date: Date = Date(),
        isCompleted: Bool = false, categoryID: UUID? = nil, categoryName: String? = nil,
        priority: TaskPriority = .none, deadline: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.isCompleted = isCompleted
        self.categoryID = categoryID
        self.categoryName = categoryName
        self.priority = priority
        self.deadline = deadline
    }
    
    // MARK: - Equatable Implementation
    static func == (lhs: ToDoItem, rhs: ToDoItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.date == rhs.date &&
               lhs.isCompleted == rhs.isCompleted &&
               lhs.categoryID == rhs.categoryID &&
               lhs.categoryName == rhs.categoryName &&
               lhs.priority == rhs.priority &&
               lhs.deadline == rhs.deadline
    }
}
