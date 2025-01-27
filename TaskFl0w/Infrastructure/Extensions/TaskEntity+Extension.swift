import CoreData
import SwiftUI

extension TaskEntity {
    var taskModel: Task {
        Task(
            id: id ?? UUID(),
            title: title ?? "",
            startTime: startTime ?? Date(),
            duration: duration,
            color: Color(hex: category?.colorHex ?? "") ?? .blue,
            icon: category?.iconName ?? "",
            category: category?.categoryModel ?? TaskCategoryModel(
                id: UUID(),
                rawValue: "Неизвестно",
                iconName: "questionmark.circle",
                color: .blue
            ),
            isCompleted: isCompleted
        )
    }
    
    static func from(_ model: Task, context: NSManagedObjectContext) -> TaskEntity {
        let entity = TaskEntity(context: context)
        entity.id = model.id
        entity.title = model.title
        entity.startTime = model.startTime
        entity.duration = model.duration
        entity.isCompleted = model.isCompleted
        
        // Находим или создаем категорию
        let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        request.predicate = NSPredicate(format: "id == %@", model.category.id as CVarArg)
        
        if let existingCategory = try? context.fetch(request).first {
            entity.category = existingCategory
        } else {
            entity.category = CategoryEntity.from(model.category, context: context)
        }
        
        return entity
    }
} 