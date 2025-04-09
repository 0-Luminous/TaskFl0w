//
//  ToDoRouterProtocol.swift
//  ToDoList
//
//  Created by Yan on 19/3/25.
//
import SwiftUI

// Добавляем импорт для модели
import Foundation

protocol ToDoRouterProtocol: AnyObject {
    associatedtype ContentView: View
    static func createModule(selectedCategory: TaskCategoryModel?) -> ContentView

    // Новый метод для шаринга
    func shareItem(_ item: ToDoItem)
}
