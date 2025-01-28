//
//  Persistence.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Создаем тестовые данные для предпросмотра
        let category = CategoryEntity(context: viewContext)
        category.id = UUID()
        category.name = "Работа"
        category.iconName = "briefcase"
        category.colorHex = "#FF0000"
        
        let task = TaskEntity(context: viewContext)
        task.id = UUID()
        task.title = "Тестовая задача"
        task.startTime = Date()
        task.endTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        task.isCompleted = false
        task.category = category
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Ошибка сохранения контекста: \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TaskFl0w")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Ошибка загрузки хранилища: \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
