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
        
        // Сначала создаем интерактор и затем устанавливаем связи
        let todoInteractor = ToDoInteractor()
        self.interactor = todoInteractor
        todoInteractor.presenter = self
    }

    func viewDidLoad() {
        interactor?.fetchItems()
    }

    func refreshItems() {
        // Обновляем список без пересоздания интерактора
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

    func editItem(id: UUID, title: String) {
        interactor?.editItem(id: id, title: title)
    }

    func shareItem(id: UUID) {
        if let item = interactor?.getItem(id: id) {
            router?.shareItem(item)
        }
    }

    func changePriority(id: UUID, priority: TaskPriority) {
        interactor?.changePriority(id: id, priority: priority)
    }

    func didChangePriority() {
        refreshItems()
    }

    func archiveCompletedTasks() {
        interactor?.archiveCompletedTasks()
    }

    func didArchiveTasks() {
        // После архивации обновляем список задач
        refreshItems()
    }

    func addItem(title: String, priority: TaskPriority, date: Date) {
        interactor?.addItem(title: title, date: date)
    }

    func addItemWithCategory(title: String, category: TaskCategoryModel, priority: TaskPriority, date: Date) {
        interactor?.addItemWithCategory(title: title, category: category, date: date)
    }
}
