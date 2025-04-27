import CoreData
//
//  ToDoInteractor.swift
//  ToDoList
//
//  Created by Yan on 19/3/25.
//
import Foundation

class ToDoInteractor: ToDoInteractorProtocol {
    weak var presenter: ToDoPresenterProtocol?
    private let viewContext = PersistenceController.shared.container.viewContext

    init() {
        // Стандартный инициализатор
        print("🔧 ToDoInteractor: Инициализация")
    }

    // Конвертирует CoreData объект в ToDoItem
    private func convertToToDoItem(_ entity: NSManagedObject) -> ToDoItem {
        let id = entity.value(forKey: "id") as! UUID
        let title = entity.value(forKey: "title") as! String
        let date = entity.value(forKey: "date") as! Date
        let isCompleted = entity.value(forKey: "isCompleted") as! Bool
        let categoryID = entity.value(forKey: "categoryID") as? UUID
        let categoryName = entity.value(forKey: "categoryName") as? String
        let priorityRaw = entity.value(forKey: "priority") as? Int ?? 0
        let priority = TaskPriority(rawValue: priorityRaw) ?? .none

        return ToDoItem(
            id: id, title: title, date: date, 
            isCompleted: isCompleted, categoryID: categoryID, categoryName: categoryName,
            priority: priority)
    }

    func fetchItems() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")

        do {
            let result = try viewContext.fetch(request)
            let items = result.map { convertToToDoItem($0) }
            presenter?.didFetchItems(ToDoItem: items)
        } catch {
            print("Ошибка при загрузке данных: \(error)")
            presenter?.didFetchItems(ToDoItem: [])
        }
    }

    func addItem(title: String) {
        print("📝 Попытка добавить новый элемент: \(title)")

        // Проверка наличия сущности
        guard let entity = NSEntityDescription.entity(forEntityName: "CDToDoItem", in: viewContext)
        else {
            print("❌ Ошибка: сущность CDToDoItem не найдена в модели CoreData")
            return
        }

        print("✅ Сущность CDToDoItem найдена")
        let newItem = NSManagedObject(entity: entity, insertInto: viewContext)

        let newID = UUID()
        newItem.setValue(newID, forKey: "id")
        newItem.setValue(title, forKey: "title")
        newItem.setValue(Date(), forKey: "date")
        newItem.setValue(false, forKey: "isCompleted")
        newItem.setValue(0, forKey: "priority")

        print("📝 Созданный элемент: ID=\(newID), title=\(title)")

        saveContext()
        print("🔄 Уведомляем презентер о добавлении элемента")
        presenter?.didAddItem()
    }

    func addItemWithCategory(title: String, category: TaskCategoryModel) {
        print("📝 Добавление новой задачи: \"\(title)\" в категорию: \"\(category.rawValue)\"")

        // Проверка наличия сущности
        guard let entity = NSEntityDescription.entity(forEntityName: "CDToDoItem", in: viewContext) else {
            print("❌ Ошибка: сущность CDToDoItem не найдена в модели CoreData")
            return
        }

        print("✅ Сущность CDToDoItem найдена")
        let newItem = NSManagedObject(entity: entity, insertInto: viewContext)

        let newID = UUID()
        newItem.setValue(newID, forKey: "id")
        newItem.setValue(title, forKey: "title")
        newItem.setValue(Date(), forKey: "date")
        newItem.setValue(false, forKey: "isCompleted")
        newItem.setValue(0, forKey: "priority")
        
        // Устанавливаем информацию о категории
        newItem.setValue(category.id, forKey: "categoryID")
        newItem.setValue(category.rawValue, forKey: "categoryName")

        print("✅ Создана задача с ID=\(newID), title=\"\(title)\", в категории=\"\(category.rawValue)\"")

        saveContext()
        presenter?.didAddItem()
    }

    func deleteItem(id: UUID) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let items = try viewContext.fetch(request)
            if let itemToDelete = items.first {
                viewContext.delete(itemToDelete)
                saveContext()
            }
            presenter?.didDeleteItem()
        } catch {
            print("Ошибка при удалении: \(error)")
        }
    }

    func toggleItem(id: UUID) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let items = try viewContext.fetch(request)
            if let item = items.first {
                let currentStatus = item.value(forKey: "isCompleted") as! Bool
                item.setValue(!currentStatus, forKey: "isCompleted")
                saveContext()
                presenter?.didToggleItem()
            }
        } catch {
            print("Ошибка при обновлении статуса: \(error)")
        }
    }

    func searchItems(query: String) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")

        if !query.isEmpty {
            request.predicate = NSPredicate(
                format: "title CONTAINS[c] %@ OR content CONTAINS[c] %@",
                query, query
            )
        }

        do {
            let result = try viewContext.fetch(request)
            let items = result.map { convertToToDoItem($0) }
            presenter?.didFetchItems(ToDoItem: items)
        } catch {
            print("Ошибка при поиске: \(error)")
            presenter?.didFetchItems(ToDoItem: [])
        }
    }

    func editItem(id: UUID, title: String) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let items = try viewContext.fetch(request)
            if let item = items.first {
                // Сохраняем старые значения категории, если они есть
                let oldCategoryID = item.value(forKey: "categoryID") as? UUID
                let oldCategoryName = item.value(forKey: "categoryName") as? String
                
                // Обновляем основные поля
                item.setValue(title, forKey: "title")
                
                // Если есть выбранная категория в viewModel, используем её
                if let presenter = presenter as? ToDoPresenter,
                   let view = presenter.view as? ListViewModel,
                   let selectedCategory = view.selectedCategory {
                    item.setValue(selectedCategory.id, forKey: "categoryID")
                    item.setValue(selectedCategory.rawValue, forKey: "categoryName")
                    print("📝 Обновлена категория для задачи: \(selectedCategory.rawValue)")
                } else if oldCategoryID != nil && oldCategoryName != nil {
                    // Сохраняем старую категорию, если новая не выбрана
                    item.setValue(oldCategoryID, forKey: "categoryID")
                    item.setValue(oldCategoryName, forKey: "categoryName")
                    print("📝 Сохранена прежняя категория для задачи: \(oldCategoryName ?? "Без имени")")
                } else {
                    // Очищаем категорию
                    item.setValue(nil, forKey: "categoryID")
                    item.setValue(nil, forKey: "categoryName")
                    print("📝 Категория для задачи очищена")
                }
                
                saveContext()
                fetchItems()
            }
        } catch {
            print("❌ Ошибка при редактировании: \(error)")
        }
    }

    func getItem(id: UUID) -> ToDoItem? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let items = try viewContext.fetch(request)
            if let item = items.first {
                return convertToToDoItem(item)
            }
        } catch {
            print("Ошибка при получении элемента: \(error)")
        }

        return nil
    }

    func changePriority(id: UUID, priority: TaskPriority) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let items = try viewContext.fetch(request)
            if let item = items.first {
                item.setValue(priority.rawValue, forKey: "priority")
                saveContext()
                presenter?.didChangePriority()
            }
        } catch {
            print("Ошибка при изменении приоритета: \(error)")
        }
    }

    func archiveCompletedTasks() {
        print("📦 Архивирование выполненных задач")
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")
        request.predicate = NSPredicate(format: "isCompleted == %@", NSNumber(value: true))

        do {
            let completedItems = try viewContext.fetch(request)
            print("📦 Найдено выполненных задач: \(completedItems.count)")
            
            // Если есть выполненные задачи, удаляем их
            if !completedItems.isEmpty {
                for item in completedItems {
                    viewContext.delete(item)
                }
                saveContext()
                print("✅ Выполненные задачи успешно перемещены в архив")
            }
            
            // Обновляем интерфейс
            presenter?.didArchiveTasks()
        } catch {
            print("❌ Ошибка при архивации задач: \(error)")
        }
    }

    // Вспомогательный метод для сохранения контекста
    private func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
                print("✅ Контекст сохранен")
            } catch {
                print("❌ Ошибка при сохранении контекста: \(error)")
            }
        }
    }
}
