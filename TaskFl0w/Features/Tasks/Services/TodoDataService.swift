//
//  TodoDataService.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation
import CoreData
import OSLog


/// Современный сервис для работы с данными ToDo задач
@MainActor
final class TodoDataService: ObservableObject {
    
    // MARK: - Properties
    private let context: NSManagedObjectContext
    private let logger = Logger(subsystem: "TaskFl0w", category: "TodoDataService")
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - CRUD Operations
    
    /// Загружает задачи для указанной даты
    func loadTasks(for date: Date) async throws -> [ToDoItem] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: true),
            NSSortDescriptor(key: "priority", ascending: false)
        ]
        
        do {
            let results = try context.fetch(request)
            let items = results.compactMap { convertToToDoItem($0) }
            logger.info("Загружено \(items.count) задач для даты \(date)")
            return items
        } catch {
            logger.error("Ошибка загрузки задач: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Добавляет новую задачу
    func addTask(
        title: String,
        category: TaskCategoryModel?,
        priority: TaskPriority,
        date: Date
    ) async throws {
        guard let entity = NSEntityDescription.entity(forEntityName: "CDToDoItem", in: context) else {
            throw TodoDataServiceError.entityNotFound
        }
        
        let newItem = NSManagedObject(entity: entity, insertInto: context)
        let newID = UUID()
        
        newItem.setValue(newID, forKey: "id")
        newItem.setValue(title, forKey: "title")
        newItem.setValue(date, forKey: "date")
        newItem.setValue(false, forKey: "isCompleted")
        newItem.setValue(Int(priority.rawValue), forKey: "priority")
        
        // Устанавливаем категорию
        if let category = category {
            newItem.setValue(category.id, forKey: "categoryID")
            newItem.setValue(category.rawValue, forKey: "categoryName")
        }
        
        try saveContext()
        logger.info("Добавлена задача: \(title) с ID: \(newID)")
    }
    
    /// Обновляет существующую задачу
    func updateTask(_ item: ToDoItem) async throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")
        request.predicate = NSPredicate(format: "id == %@", item.id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw TodoDataServiceError.taskNotFound
            }
            
            entity.setValue(item.title, forKey: "title")
            entity.setValue(item.date, forKey: "date")
            entity.setValue(item.isCompleted, forKey: "isCompleted")
            entity.setValue(Int(item.priority.rawValue), forKey: "priority")
            entity.setValue(item.categoryID, forKey: "categoryID")
            entity.setValue(item.categoryName, forKey: "categoryName")
            
            // 🔧 ИСПРАВЛЕНИЕ: Принудительное обновление deadline
            entity.setValue(item.deadline, forKey: "deadline")
            
            try saveContext()
            logger.info("✅ Обновлена задача: \(item.id) с deadline: \(item.deadline?.description ?? "nil")")
        } catch {
            logger.error("Ошибка обновления задачи: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Удаляет задачу по ID
    func deleteTask(with id: UUID) async throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            guard let taskToDelete = results.first else {
                throw TodoDataServiceError.taskNotFound
            }
            
            context.delete(taskToDelete)
            try saveContext()
            logger.info("Удалена задача: \(id)")
        } catch {
            logger.error("Ошибка удаления задачи: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Получает задачу по ID
    func getTask(with id: UUID) async throws -> ToDoItem? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            guard let entity = results.first else { return nil }
            return convertToToDoItem(entity)
        } catch {
            logger.error("Ошибка получения задачи: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Поиск задач по запросу
    func searchTasks(query: String) async throws -> [ToDoItem] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")
        
        if !query.isEmpty {
            request.predicate = NSPredicate(
                format: "title CONTAINS[c] %@",
                query
            )
        }
        
        request.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: false),
            NSSortDescriptor(key: "priority", ascending: false)
        ]
        
        do {
            let results = try context.fetch(request)
            let items = results.compactMap { convertToToDoItem($0) }
            logger.info("Найдено \(items.count) задач по запросу: \(query)")
            return items
        } catch {
            logger.error("Ошибка поиска задач: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Загружает все завершенные (архивные) задачи
    func loadAllCompletedTasks() async throws -> [ToDoItem] {
        logger.info("🔍 Начинаем загрузку всех архивных задач из БД...")
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")
        request.predicate = NSPredicate(format: "isCompleted == %@", NSNumber(value: true))
        request.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: false),
            NSSortDescriptor(key: "priority", ascending: false)
        ]
        
        do {
            let results = try context.fetch(request)
            logger.info("📊 Найдено \(results.count) записей с isCompleted == true в БД")
            
            // Дебаг: показываем все найденные записи
            for (index, entity) in results.enumerated() {
                let title = entity.value(forKey: "title") as? String ?? "Unknown"
                let isCompleted = entity.value(forKey: "isCompleted") as? Bool ?? false
                let categoryID = entity.value(forKey: "categoryID") as? UUID
                logger.info("📝 Запись \(index + 1): \(title) (isCompleted: \(isCompleted), categoryID: \(categoryID?.uuidString ?? "nil"))")
            }
            
            let items = results.compactMap { convertToToDoItem($0) }
            logger.info("✅ Успешно конвертировано \(items.count) архивных задач")
            
            // Дебаг: показываем финальные задачи
            for (index, item) in items.enumerated() {
                logger.info("🎯 Архивная задача \(index + 1): \(item.title) (categoryID: \(item.categoryID?.uuidString ?? "nil"))")
            }
            
            return items
        } catch {
            logger.error("❌ Ошибка загрузки архивных задач: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Загружает ВСЕ задачи из базы данных (для дебаггинга)
    func loadAllTasks() async throws -> [ToDoItem] {
        logger.info("🔍 Загружаем ВСЕ задачи из БД для дебаггинга...")
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")
        request.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: false),
            NSSortDescriptor(key: "isCompleted", ascending: true)
        ]
        
        do {
            let results = try context.fetch(request)
            logger.info("📊 Всего найдено записей в БД: \(results.count)")
            
            // Дебаг: показываем все найденные записи
            var completedCount = 0
            var activeCount = 0
            
            for (index, entity) in results.enumerated() {
                let title = entity.value(forKey: "title") as? String ?? "Unknown"
                let isCompleted = entity.value(forKey: "isCompleted") as? Bool ?? false
                let categoryID = entity.value(forKey: "categoryID") as? UUID
                let dateCreated = entity.value(forKey: "date") as? Date
                
                if isCompleted {
                    completedCount += 1
                    logger.info("✅ Завершенная задача \(index + 1): \(title) (categoryID: \(categoryID?.uuidString ?? "nil"), дата: \(dateCreated?.description ?? "nil"))")
                } else {
                    activeCount += 1
                    logger.info("⏳ Активная задача \(index + 1): \(title) (categoryID: \(categoryID?.uuidString ?? "nil"), дата: \(dateCreated?.description ?? "nil"))")
                }
            }
            
            logger.info("📈 Статистика БД: завершенных \(completedCount), активных \(activeCount)")
            
            let items = results.compactMap { convertToToDoItem($0) }
            logger.info("✅ Успешно конвертировано \(items.count) задач")
            
            return items
        } catch {
            logger.error("❌ Ошибка загрузки всех задач: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Архивирует выполненные задачи
    func archiveCompletedTasks() async throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")
        request.predicate = NSPredicate(format: "isCompleted == %@", NSNumber(value: true))
        
        do {
            let completedItems = try context.fetch(request)
            for item in completedItems {
                context.delete(item)
            }
            
            try saveContext()
            logger.info("Архивировано \(completedItems.count) выполненных задач")
        } catch {
            logger.error("Ошибка архивации задач: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func convertToToDoItem(_ entity: NSManagedObject) -> ToDoItem? {
        guard let id = entity.value(forKey: "id") as? UUID,
              let title = entity.value(forKey: "title") as? String,
              let date = entity.value(forKey: "date") as? Date,
              let isCompleted = entity.value(forKey: "isCompleted") as? Bool else {
            logger.warning("Не удалось конвертировать entity в ToDoItem")
            return nil
        }
        
        let categoryID = entity.value(forKey: "categoryID") as? UUID
        let categoryName = entity.value(forKey: "categoryName") as? String
        let priorityRaw = entity.value(forKey: "priority") as? Int ?? 0
        let priority = TaskPriority(rawValue: priorityRaw) ?? .none
        
        // 🔧 ИСПРАВЛЕНИЕ: Принудительно загружаем deadline из базы данных
        let deadline = entity.value(forKey: "deadline") as? Date
        
        // 📝 ДЕБАГ: Логируем загруженные данные
        logger.debug("📦 Загружена задача \(id): deadline = \(deadline?.description ?? "nil")")
        
        return ToDoItem(
            id: id,
            title: title,
            date: date,
            isCompleted: isCompleted,
            categoryID: categoryID,
            categoryName: categoryName,
            priority: priority,
            deadline: deadline // Теперь загружаем deadline из CoreData
        )
    }
    
    private func saveContext() throws {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            logger.debug("Контекст сохранен успешно")
        } catch {
            logger.error("Ошибка сохранения контекста: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Errors
enum TodoDataServiceError: LocalizedError {
    case entityNotFound
    case taskNotFound
    case saveError(Error)
    
    var errorDescription: String? {
        switch self {
        case .entityNotFound:
            return "Сущность CDToDoItem не найдена в модели CoreData"
        case .taskNotFound:
            return "Задача не найдена"
        case .saveError(let error):
            return "Ошибка сохранения: \(error.localizedDescription)"
        }
    }
} 
