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
    var content: String
    var date: Date
    var isCompleted: Bool
    var categoryID: UUID?
    var categoryName: String?

    init(
        id: UUID = UUID(), title: String, content: String, date: Date = Date(),
        isCompleted: Bool = false, categoryID: UUID? = nil, categoryName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.date = date
        self.isCompleted = isCompleted
        self.categoryID = categoryID
        self.categoryName = categoryName
    }
}
