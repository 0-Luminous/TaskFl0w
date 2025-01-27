import Foundation
import CoreData

// Синглтон для хранения общего состояния
class SharedStateService {
    static let shared = SharedStateService()
    
    let context: NSManagedObjectContext
    
    var tasks: [Task] = [] {
        didSet {
            // Уведомляем подписчиков об изменении
            notifyTasksUpdated()
        }
    }
    
    private var tasksUpdateCallbacks: [() -> Void] = []
    
    private init() {
        // Получаем контекст из контейнера CoreData
        let container = NSPersistentContainer(name: "TaskFl0w")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Ошибка загрузки Core Data: \(error.localizedDescription)")
            }
        }
        self.context = container.viewContext
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Ошибка сохранения контекста: \(error.localizedDescription)")
            }
        }
    }
    
    func subscribeToTasksUpdates(_ callback: @escaping () -> Void) {
        tasksUpdateCallbacks.append(callback)
    }
    
    private func notifyTasksUpdated() {
        tasksUpdateCallbacks.forEach { $0() }
    }
} 