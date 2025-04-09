//
//  ToDoPresenter.swift
//  ToDoList
//
//  Created by Yan on 19/3/25.
//
import Foundation

class ToDoPresenter: ToDoPresenterProtocol {
    weak var view: ToDoViewProtocol?
    var interactor: ToDoInteractorProtocol?
    var router: (any ToDoRouterProtocol)?

    init(view: ToDoViewProtocol) {
        self.view = view
    }

    func viewDidLoad() {
        interactor?.fetchItems()
    }

    func didFetchItems(ToDoItem items: [ToDoItem]) {
        view?.displayItems(items)
    }

    func didAddItem() {
        print("🔄 Presenter: Запрос на обновление списка после добавления")
        interactor?.fetchItems()
    }

    func didDeleteItem() {
        interactor?.fetchItems()
    }

    func didToggleItem() {
        interactor?.fetchItems()
    }

    func handleSearch(query: String) {
        interactor?.searchItems(query: query)
    }

    func toggleItem(id: UUID) {
        interactor?.toggleItem(id: id)
    }

    func deleteItem(id: UUID) {
        interactor?.deleteItem(id: id)
    }

    func addItem(title: String, content: String) {
        interactor?.addItem(title: title, content: content)
    }

    func addItemWithCategory(title: String, content: String, category: TaskCategoryModel) {
        interactor?.addItemWithCategory(title: title, content: content, category: category)
    }

    func editItem(id: UUID, title: String, content: String) {
        interactor?.editItem(id: id, title: title, content: content)
    }

    func shareItem(id: UUID) {
        if let item = interactor?.getItem(id: id) {
            router?.shareItem(item)
        }
    }
}
