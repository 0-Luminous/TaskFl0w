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

    // Конвертирует CoreData объект в ToDoItem
    private func convertToToDoItem(_ entity: NSManagedObject) -> ToDoItem {
        let id = entity.value(forKey: "id") as! UUID
        let title = entity.value(forKey: "title") as! String
        let content = entity.value(forKey: "content") as! String
        let date = entity.value(forKey: "date") as! Date
        let isCompleted = entity.value(forKey: "isCompleted") as! Bool

        return ToDoItem(
            id: id, title: title, content: content, date: date, isCompleted: isCompleted)
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

    func addItem(title: String, content: String) {
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
        newItem.setValue(content, forKey: "content")
        newItem.setValue(Date(), forKey: "date")
        newItem.setValue(false, forKey: "isCompleted")

        print("📝 Созданный элемент: ID=\(newID), title=\(title)")

        saveContext()
        print("🔄 Уведомляем презентер о добавлении элемента")
        presenter?.didAddItem()
    }

    func addItemWithCategory(title: String, content: String, category: TaskCategoryModel) {
        print("📝 Попытка добавить новый элемент с категорией: \(title), категория: \(category.rawValue)")

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
        newItem.setValue(content, forKey: "content")
        newItem.setValue(Date(), forKey: "date")
        newItem.setValue(false, forKey: "isCompleted")
        newItem.setValue(category.id, forKey: "categoryID")
        newItem.setValue(category.rawValue, forKey: "categoryName")

        print("📝 Созданный элемент с категорией: ID=\(newID), title=\(title), категория=\(category.rawValue)")

        saveContext()
        print("🔄 Уведомляем презентер о добавлении элемента с категорией")
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

    func editItem(id: UUID, title: String, content: String) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let items = try viewContext.fetch(request)
            if let item = items.first {
                item.setValue(title, forKey: "title")
                item.setValue(content, forKey: "content")
                saveContext()
                fetchItems()
            }
        } catch {
            print("Ошибка при редактировании: \(error)")
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

    // Вспомогательный метод для сохранения контекста
    private func saveContext() {
        do {
            if viewContext.hasChanges {
                try viewContext.save()
                print("✅ Данные успешно сохранены в CoreData")
            } else {
                print("⚠️ Нет изменений для сохранения в CoreData")
            }
        } catch {
            print("❌ Ошибка при сохранении контекста: \(error)")
            // Добавим более подробную информацию об ошибке
            if let nserror = error as NSError? {
                print("Подробная информация об ошибке: \(nserror.userInfo)")
            }
        }
    }
}
