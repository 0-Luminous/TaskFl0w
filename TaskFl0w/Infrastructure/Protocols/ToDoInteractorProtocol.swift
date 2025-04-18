//
//  ToDoInteractorProtocol.swift
//  ToDoList
//
//  Created by Yan on 19/3/25.
//
import Foundation
import SwiftUI

protocol ToDoInteractorProtocol: AnyObject {
    func fetchItems()
    func addItem(title: String, content: String)
    func addItemWithCategory(title: String, content: String, category: TaskCategoryModel)
    func deleteItem(id: UUID)
    func toggleItem(id: UUID)
    func searchItems(query: String)
    func changePriority(id: UUID, priority: TaskPriority)

    // Новые методы
    func editItem(id: UUID, title: String, content: String)
    func getItem(id: UUID) -> ToDoItem?
}
