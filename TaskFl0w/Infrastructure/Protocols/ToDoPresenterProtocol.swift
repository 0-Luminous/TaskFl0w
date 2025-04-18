//
//  ToDoPresenterProtocol.swift
//  ToDoList
//
//  Created by Yan on 19/3/25.
//
import Foundation
import SwiftUI

protocol ToDoPresenterProtocol: AnyObject {
    func viewDidLoad()
    func refreshItems()
    func didFetchItems(ToDoItem: [ToDoItem])
    func didAddItem()
    func didDeleteItem()
    func didToggleItem()
    func handleSearch(query: String)
    func didChangePriority()

    // Добавим методы для взаимодействия с View
    func toggleItem(id: UUID)
    func deleteItem(id: UUID)
    func addItem(title: String, content: String)
    func addItemWithCategory(title: String, content: String, category: TaskCategoryModel)
    func changePriority(id: UUID, priority: TaskPriority)

    // Новые методы для контекстного меню
    func editItem(id: UUID, title: String, content: String)
    func shareItem(id: UUID)
}
