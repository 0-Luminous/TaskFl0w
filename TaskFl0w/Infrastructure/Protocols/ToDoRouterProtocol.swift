//
//  ToDoRouterProtocol.swift
//  ToDoList
//
//  Created by Yan on 19/3/25.
//
import SwiftUI

protocol ToDoRouterProtocol: AnyObject {
    associatedtype ContentView: View
    static func createModule() -> ContentView

    // Новый метод для шаринга
    func shareItem(_ item: ToDoItem)
}
