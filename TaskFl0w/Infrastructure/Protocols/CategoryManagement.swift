import CoreData
import Foundation
import SwiftUI

@MainActor
protocol CategoryManagementProtocol {
    var categories: [TaskCategoryModel] { get }  // Только get
    func addCategory(_ category: TaskCategoryModel)
    func updateCategory(_ category: TaskCategoryModel)
    func removeCategory(_ category: TaskCategoryModel)
    func fetchCategories()
}

@MainActor
class CategoryManagement: CategoryManagementProtocol {
    private let context: NSManagedObjectContext
    private let sharedState: SharedStateService

    // Удаляем хардкод категорий
    private var _categories: [TaskCategoryModel] = []

    var categories: [TaskCategoryModel] { _categories }

    init(context: NSManagedObjectContext, sharedState: SharedStateService) {
        self.context = context
        self.sharedState = sharedState
        fetchCategories()
    }

    func fetchCategories() {
        let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")

        do {
            let categoryEntities = try context.fetch(request)
            _categories = categoryEntities.map { $0.categoryModel }
            
            // Обновляем цвета категорий для виджетов
            CategoryColorSharing.shared.updateCategoryColors(categories: _categories)
        } catch {
            print("Ошибка при загрузке категорий: \(error)")
        }
    }

    func addCategory(_ category: TaskCategoryModel) {
        guard validateCategory(category) else { return }

        // Создаем сущность CategoryEntity и сохраняем её
        _ = CategoryEntity.from(category, context: context)
        _categories.append(category)
        saveContext()
    }

    func updateCategory(_ category: TaskCategoryModel) {
        guard validateCategory(category) else { return }

        let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        request.predicate = NSPredicate(format: "id == %@", category.id as CVarArg)

        do {
            if let existingCategory = try context.fetch(request).first {
                existingCategory.name = category.rawValue
                existingCategory.iconName = category.iconName
                existingCategory.colorHex = category.color.toHex()

                if let index = _categories.firstIndex(where: { $0.id == category.id }) {
                    _categories[index] = category
                }

                saveContext()

                // Обновляем связанные задачи
                updateRelatedTasks(category)
            }
        } catch {
            print("Ошибка при обновлении категории: \(error)")
        }
    }

    func removeCategory(_ category: TaskCategoryModel) {
        let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        request.predicate = NSPredicate(format: "id == %@", category.id as CVarArg)

        do {
            if let categoryToDelete = try context.fetch(request).first {
                context.delete(categoryToDelete)
                _categories.removeAll { $0.id == category.id }

                // Удаляем связанные задачи
                sharedState.tasks.removeAll { task in
                    task.category.id == category.id
                }

                saveContext()
            }
        } catch {
            print("Ошибка при удалении категории: \(error)")
        }
    }

    private func updateRelatedTasks(_ category: TaskCategoryModel) {
        sharedState.tasks = sharedState.tasks.map { task in
            if task.category.id == category.id {
                return TaskOnRing(
                    id: task.id,
                    startTime: task.startTime,
                    endTime: task.endTime,
                    color: category.color,
                    icon: category.iconName,
                    category: category,
                    isCompleted: task.isCompleted
                )
            }
            return task
        }
    }

    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Ошибка сохранения контекста: \(error)")
            }
        }
    }

    private func validateCategory(_ category: TaskCategoryModel) -> Bool {
        // Пример простой валидации
        return !category.rawValue.isEmpty && !category.iconName.isEmpty
    }
}
