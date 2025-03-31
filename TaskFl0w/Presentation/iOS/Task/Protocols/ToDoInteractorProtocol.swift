//
//  ToDoInteractorProtocol.swift
//  ToDoList
//
//  Created by Yan on 19/3/25.
//
import Foundation

protocol ToDoInteractorProtocol: AnyObject {
    func fetchItems()
    func addItem(title: String, content: String)
    func deleteItem(id: UUID)
    func toggleItem(id: UUID)
    func searchItems(query: String)

    // Новые методы
    func editItem(id: UUID, title: String, content: String)
    func getItem(id: UUID) -> ToDoItem?
}
