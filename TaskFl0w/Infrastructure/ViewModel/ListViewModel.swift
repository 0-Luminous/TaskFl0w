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
    @Published var showCompletedTasksOnly: Bool = false
    @Published var selectedTasks: Set<UUID> = []
    @Published var isSelectionMode: Bool = false
    
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
    
    // Функция для сохранения новой задачи
    func saveNewTask(title: String) {
        if !title.isEmpty {
            if let category = selectedCategory {
                presenter?.addItemWithCategory(
                    title: title,
                    category: category
                )
            } else {
                presenter?.addItem(
                    title: title
                )
            }
        }
    }
    
    // Фильтрация и сортировка задач
    func getFilteredItems() -> [ToDoItem] {
        var filteredItems: [ToDoItem]
        
        // Сначала фильтруем по категории, если она выбрана
        if let selectedCategory = selectedCategory {
            filteredItems = items.filter { item in
                item.categoryID == selectedCategory.id
            }
        } else {
            filteredItems = items
        }
        
        // Если включен режим просмотра выполненных задач, отфильтровываем только их
        if showCompletedTasksOnly {
            filteredItems = filteredItems.filter { item in
                item.isCompleted
            }
        }
        
        // Сортируем задачи
        return filteredItems.sorted { (item1, item2) -> Bool in
            // Если мы в режиме выполненных задач
            if showCompletedTasksOnly {
                // Сначала сортируем по приоритету
                if item1.priority != item2.priority {
                    return item1.priority.rawValue > item2.priority.rawValue
                }
                
                // Если приоритеты одинаковые, сортируем по дате завершения
                // (от новых к старым)
                return item1.date > item2.date
            } else {
                // Стандартная сортировка
                // Если статус завершения разный, незавершенные идут вначале
                if item1.isCompleted != item2.isCompleted {
                    return !item1.isCompleted
                }
                
                // Если статус завершения одинаковый, сортируем по приоритету
                return item1.priority.rawValue > item2.priority.rawValue
            }
        }
    }
    
    // Методы для работы с выбранными задачами
    func toggleTaskSelection(taskId: UUID) {
        if selectedTasks.contains(taskId) {
            selectedTasks.remove(taskId)
        } else {
            selectedTasks.insert(taskId)
        }
    }
    
    func deleteSelectedTasks() {
        for taskId in selectedTasks {
            presenter?.deleteItem(id: taskId)
        }
        // Очищаем множество выбранных задач
        selectedTasks.removeAll()
    }
    
    func unarchiveSelectedTasks() {
        for taskId in selectedTasks {
            presenter?.toggleItem(id: taskId)
        }
        selectedTasks.removeAll()
    }
    
    func setPriorityForSelectedTasks(_ priority: TaskPriority) {
        for taskId in selectedTasks {
            presenter?.changePriority(id: taskId, priority: priority)
        }
        // Выходим из режима выбора после установки приоритета
        isSelectionMode = false
    }
    
    // Вспомогательные методы для приоритетов
    func getPriorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .high:
            return Color.red
        case .medium:
            return Color.orange
        case .low:
            return Color.green
        case .none:
            return Color.gray
        }
    }

    func priorityIcon(for priority: TaskPriority) -> String {
        switch priority {
        case .high:
            return "exclamationmark.triangle.fill"
        case .medium:
            return "exclamationmark.circle.fill"
        case .low:
            return "arrow.up.circle.fill"
        case .none:
            return "list.bullet"
        }
    }

    func getPriorityText(for priority: TaskPriority) -> String {
        switch priority {
        case .high:
            return "Высокий приоритет"
        case .medium:
            return "Средний приоритет"
        case .low:
            return "Низкий приоритет"
        case .none:
            return "Без приоритета"
        }
    }
}
