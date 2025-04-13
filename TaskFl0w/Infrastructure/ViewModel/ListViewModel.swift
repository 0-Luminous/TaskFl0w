//
//  ListViewModel.swift
//  TaskFl0w
//
//  Created by Yan on 25/3/25.
//

import Combine
import Foundation
import SwiftUI

class ListViewModel: ObservableObject, ToDoViewProtocol {
    @Published var items: [ToDoItem] = []
    @Published var searchText: String = "" {
        didSet {
            presenter?.handleSearch(query: searchText)
        }
    }
    @Published var isAddingNewItem: Bool = false
    @Published var editingItem: ToDoItem? = nil
    @Published var selectedCategory: TaskCategoryModel? = nil

    var presenter: ToDoPresenterProtocol?

    init(selectedCategory: TaskCategoryModel? = nil) {
        self.selectedCategory = selectedCategory
        self.presenter = ToDoPresenter(view: self)
        presenter?.viewDidLoad()
    }

    func displayItems(_ items: [ToDoItem]) {
        DispatchQueue.main.async {
            self.items = items
        }
    }

    func onViewDidLoad() {
        print("🚀 ContentViewModel: onViewDidLoad вызван")
        presenter?.viewDidLoad()
    }

    func refreshData() {
        print("🔄 ContentViewModel: refreshData вызван")
        presenter?.refreshItems()
    }

    func showAddNewItemForm() {
        DispatchQueue.main.async {
            self.isAddingNewItem = true
        }
    }
    
    func hideAddNewItemForm() {
        DispatchQueue.main.async {
            self.isAddingNewItem = false
        }
    }
}
