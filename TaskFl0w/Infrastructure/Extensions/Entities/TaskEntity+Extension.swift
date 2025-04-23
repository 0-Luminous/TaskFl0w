//
//  TaskEntity+Extension.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import CoreData
import SwiftUI

extension TaskEntity {
    var taskModel: TaskOnRing {
        let calendar = Calendar.current

        // Нормализуем время начала
        let storedStartTime = startTime ?? Date()
        let startComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: storedStartTime
        )

        var normalizedStartComponents = DateComponents()
        normalizedStartComponents.year = startComponents.year
        normalizedStartComponents.month = startComponents.month
        normalizedStartComponents.day = startComponents.day
        normalizedStartComponents.hour = startComponents.hour
        normalizedStartComponents.minute = startComponents.minute
        normalizedStartComponents.timeZone = TimeZone.current

        // Нормализуем время окончания
        let storedEndTime = endTime ?? Date()
        let endComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: storedEndTime
        )

        var normalizedEndComponents = DateComponents()
        normalizedEndComponents.year = endComponents.year
        normalizedEndComponents.month = endComponents.month
        normalizedEndComponents.day = endComponents.day
        normalizedEndComponents.hour = endComponents.hour
        normalizedEndComponents.minute = endComponents.minute
        normalizedEndComponents.timeZone = TimeZone.current

        let normalizedStartTime = calendar.date(from: normalizedStartComponents) ?? storedStartTime
        let normalizedEndTime = calendar.date(from: normalizedEndComponents) ?? storedEndTime

        return TaskOnRing(
            id: id ?? UUID(),
            startTime: normalizedStartTime,
            endTime: normalizedEndTime,
            color: Color(hex: category?.colorHex ?? "") ?? .blue,
            icon: category?.iconName ?? "",
            category: category?.categoryModel
                ?? TaskCategoryModel(
                    id: UUID(),
                    rawValue: "Неизвестно",
                    iconName: "questionmark.circle",
                    color: .blue
                ),
            isCompleted: isCompleted
        )
    }

    static func from(_ model: TaskOnRing, context: NSManagedObjectContext) -> TaskEntity {
        let entity = TaskEntity(context: context)
        entity.id = model.id

        let calendar = Calendar.current

        // Нормализуем время начала с учетом временной зоны
        let startComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .timeZone],
            from: model.startTime
        )

        // Нормализуем время окончания с учетом временной зоны
        let endComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .timeZone],
            from: model.endTime
        )

        entity.startTime = calendar.date(from: startComponents)
        entity.endTime = calendar.date(from: endComponents)
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
