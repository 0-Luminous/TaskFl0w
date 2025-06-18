//
//  Persistence.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import CoreData
import OSLog

// MARK: - Persistence Errors
enum PersistenceError: Error, LocalizedError {
    case saveContextFailed(NSError)
    case storeLoadFailed(NSError)
    case previewDataCreationFailed(NSError)
    
    var errorDescription: String? {
        switch self {
        case .saveContextFailed(let error):
            return "Ошибка сохранения контекста: \(error.localizedDescription)"
        case .storeLoadFailed(let error):
            return "Ошибка загрузки хранилища: \(error.localizedDescription)"
        case .previewDataCreationFailed(let error):
            return "Ошибка создания тестовых данных: \(error.localizedDescription)"
        }
    }
}

// MARK: - Persistence Controller
final class PersistenceController {
    static let shared: PersistenceController = {
        do {
            return try PersistenceController()
        } catch {
            // Fallback: если основной инициализатор не работает, используем in-memory
            Logger(subsystem: "TaskFl0w", category: "Persistence")
                .critical("Критическая ошибка инициализации Core Data: \(error.localizedDescription). Используем in-memory store.")
            
            do {
                return try PersistenceController(inMemory: true)
            } catch {
                // Если даже in-memory не работает, это критическая ошибка системы
                fatalError("Невозможно инициализировать Core Data даже с in-memory store: \(error)")
            }
        }
    }()
    
    private let logger = Logger(subsystem: "TaskFl0w", category: "Persistence")

    static let preview: PersistenceController = {
        do {
            return try PersistenceController(inMemory: true)
        } catch {
            // В крайнем случае для preview
            Logger(subsystem: "TaskFl0w", category: "Persistence")
                .error("Ошибка создания preview контроллера: \(error.localizedDescription)")
            
            // Возвращаем shared как fallback
            return shared
        }
    }()
    
    let container: NSPersistentContainer

    init(inMemory: Bool = false) throws {
        container = NSPersistentContainer(name: "TaskFl0w")
        
        if inMemory {
            guard let storeDescription = container.persistentStoreDescriptions.first else {
                throw PersistenceError.storeLoadFailed(
                    NSError(domain: "PersistenceController", code: -1, 
                           userInfo: [NSLocalizedDescriptionKey: "No store description found"])
                )
            }
            storeDescription.url = URL(fileURLWithPath: "/dev/null")
        }
        
        try loadPersistentStores()
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Private Methods
    private func loadPersistentStores() throws {
        var loadError: Error?
        
        container.loadPersistentStores { [weak self] storeDescription, error in
            if let error = error as NSError? {
                self?.logger.error("Ошибка загрузки хранилища: \(error.localizedDescription)")
                loadError = PersistenceError.storeLoadFailed(error)
            } else {
                self?.logger.info("Хранилище успешно загружено: \(storeDescription.url?.absoluteString ?? "unknown")")
            }
        }
        
        if let error = loadError {
            throw error
        }
    }
    
    @MainActor
    private func createPreviewData() throws {
        // TODO: Implement preview data creation once Core Data model is properly set up
        logger.info("Preview data creation skipped - Core Data model needs to be configured")
        
        /*
        let viewContext = container.viewContext
        
        do {
            // Создаем тестовые данные для предпросмотра
            let category = CategoryEntity(context: viewContext)
            category.id = UUID()
            category.name = "Работа"
            category.iconName = "briefcase"
            category.colorHex = "#FF0000"
            
            let task = TaskEntity(context: viewContext)
            task.id = UUID()
            task.startTime = Date()
            task.endTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            task.isCompleted = false
            task.category = category
            
            try viewContext.save()
            logger.info("Тестовые данные успешно созданы")
        } catch {
            logger.error("Ошибка создания тестовых данных: \(error.localizedDescription)")
            throw PersistenceError.previewDataCreationFailed(error as NSError)
        }
        */
    }
    
    // MARK: - Public Methods
    func save() throws {
        let context = container.viewContext
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            logger.info("Контекст успешно сохранен")
        } catch {
            logger.error("Ошибка сохранения контекста: \(error.localizedDescription)")
            throw PersistenceError.saveContextFailed(error as NSError)
        }
    }
}
