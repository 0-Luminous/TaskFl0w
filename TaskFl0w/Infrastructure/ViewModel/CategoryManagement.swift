import Foundation
import CoreData
import SwiftUI

protocol CategoryManagementProtocol {
    var categories: [TaskCategoryModel] { get }  // Только get
    func addCategory(_ category: TaskCategoryModel)
    func updateCategory(_ category: TaskCategoryModel)
    func removeCategory(_ category: TaskCategoryModel)
    func fetchCategories()
}

class CategoryManagement: CategoryManagementProtocol {
    private let context: NSManagedObjectContext
    private let sharedState: SharedStateService
    
    // Приватное хранилище категорий
    private var _categories: [TaskCategoryModel] = [
        TaskCategoryModel(id: UUID(), rawValue: "Работа", iconName: "macbook", color: .blue),
        TaskCategoryModel(id: UUID(), rawValue: "Спорт", iconName: "figure.strengthtraining.traditional", color: .green),
        TaskCategoryModel(id: UUID(), rawValue: "Развлечения", iconName: "gamecontroller", color: .red)
    ]
    
    // Публичный доступ только для чтения
    var categories: [TaskCategoryModel] { _categories }
    
    init(context: NSManagedObjectContext, sharedState: SharedStateService = .shared) {
        self.context = context
        self.sharedState = sharedState
        fetchCategories()
    }
    
    func fetchCategories() {
        let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        
        do {
            let categoryEntities = try context.fetch(request)
            _categories = categoryEntities.map { $0.categoryModel }
        } catch {
            print("Ошибка при загрузке категорий: \(error)")
        }
    }
    
    func addCategory(_ category: TaskCategoryModel) {
        _categories.append(category)
    }
    
    func updateCategory(_ category: TaskCategoryModel) {
        if let index = _categories.firstIndex(where: { $0.id == category.id }) {
            _categories[index] = category
            
            // Обновляем все задачи через общее хранилище
            sharedState.tasks = sharedState.tasks.map { task in
                if task.category.id == category.id {
                    return Task(
                        id: task.id,
                        title: task.title,
                        startTime: task.startTime,
                        duration: task.duration,
                        color: category.color,
                        icon: category.iconName,
                        category: category,
                        isCompleted: task.isCompleted
                    )
                }
                return task
            }
        }
    }
    
    func removeCategory(_ category: TaskCategoryModel) {
        // Удаляем все задачи через общее хранилище
        sharedState.tasks.removeAll { task in
            task.category.id == category.id
        }
        
        // Удаляем саму категорию
        _categories.removeAll { $0.id == category.id }
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
} 