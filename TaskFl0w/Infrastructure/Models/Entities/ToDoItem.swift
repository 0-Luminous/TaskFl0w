//
//  ToDoItem.swift
//  ToDoList
//
//  Created by Yan on 19/3/25.
//
import Foundation

struct ToDoItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var date: Date
    var isCompleted: Bool
    var categoryID: UUID?
    var categoryName: String?
    var priority: TaskPriority

    init(
        id: UUID = UUID(), title: String, date: Date = Date(),
        isCompleted: Bool = false, categoryID: UUID? = nil, categoryName: String? = nil,
        priority: TaskPriority = .none
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.isCompleted = isCompleted
        self.categoryID = categoryID
        self.categoryName = categoryName
        self.priority = priority
    }
}
