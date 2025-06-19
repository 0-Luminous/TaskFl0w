//
//  ToDoViewProtocol.swift
//  ToDoList
//
//  Created by Yan on 19/3/25.
//

protocol ToDoViewProtocol: AnyObject {
    func displayItems(_ items: [ToDoItem])
}
