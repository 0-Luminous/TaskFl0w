import CoreData
import Foundation
import SwiftUI

protocol TaskManagementProtocol {
    func addTask(_ task: TaskOnRing)
    func updateTask(_ task: TaskOnRing)
    func removeTask(_ task: TaskOnRing)
    func updateTaskStartTimeKeepingEnd(_ task: TaskOnRing, newStartTime: Date)
    func updateTaskStartTime(_ task: TaskOnRing, newStartTime: Date)
    func updateTaskDuration(_ task: TaskOnRing, newEndTime: Date)
    func fetchTasks()
    func createTask(startTime: Date, endTime: Date, category: TaskCategoryModel) async throws
    func updateTask(_ task: TaskOnRing, newStartTime: Date?, newEndTime: Date?) async throws
    func updateWholeTask(_ task: TaskOnRing, newStartTime: Date, newEndTime: Date)
}

class TaskManagement: TaskManagementProtocol {
    private let context: NSManagedObjectContext
    private let sharedState: SharedStateService
    
    // Делаем selectedDate изменяемым свойством
    var selectedDate: Date {
        didSet {
            // При необходимости можно добавить дополнительную логику при изменении даты
        }
    }

    // Добавляем мьютекс для синхронизации операций
    private let operationQueue = DispatchQueue(label: "taskManagement.queue", qos: .userInitiated)

    init(sharedState: SharedStateService, selectedDate: Date) {
        self.sharedState = sharedState
        self.context = sharedState.context
        self.selectedDate = selectedDate
        fetchTasks()
    }

    func fetchTasks() {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
            
            do {
                let taskEntities = try self.context.fetch(request)
                let fetchedTasks = taskEntities.map { $0.taskModel }
                
                DispatchQueue.main.async {
                    self.sharedState.tasks = fetchedTasks
                    print("✅ Загружено \(fetchedTasks.count) задач из базы данных")
                }
            } catch {
                print("❌ Ошибка при загрузке задач: \(error)")
            }
        }
    }

    func addTask(_ task: TaskOnRing) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Убираем все проверки валидации и дублирования
            // Просто нормализуем и добавляем задачу
            let normalizedTask = self.normalizeTask(task)
            
            // Создаем TaskEntity
            let taskEntity = TaskEntity.from(normalizedTask, context: self.context)
            
            // Сохраняем контекст сначала
            self.saveContext()
            
            // Обновляем память
            DispatchQueue.main.async {
                self.sharedState.tasks.append(normalizedTask)
                print("✅ Задача добавлена без проверок")
            }
        }
    }

    func updateTask(_ task: TaskOnRing) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
            request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

            do {
                if let existingTask = try self.context.fetch(request).first {
                    let normalizedTask = self.normalizeTask(task)
                    
                    // Обновляем данные в CoreData
                    existingTask.startTime = normalizedTask.startTime
                    existingTask.endTime = normalizedTask.endTime
                    existingTask.isCompleted = normalizedTask.isCompleted

                    // Обновляем категорию
                    self.updateTaskCategory(existingTask, with: normalizedTask.category)
                    
                    // Сохраняем изменения сначала
                    self.saveContext()
                    
                    // Затем обновляем память
                    DispatchQueue.main.async {
                        if let index = self.sharedState.tasks.firstIndex(where: { $0.id == task.id }) {
                            self.sharedState.tasks[index] = normalizedTask
                            print("✅ Задача обновлена в памяти")
                        }
                    }
                } else {
                    print("❌ Задача с ID \(task.id) не найдена для обновления")
                }
            } catch {
                print("❌ Ошибка при обновлении задачи: \(error)")
            }
        }
    }

    func removeTask(_ task: TaskOnRing) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
            request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

            do {
                if let taskToDelete = try self.context.fetch(request).first {
                    print("✅ Найдена задача для удаления с ID: \(task.id)")
                    
                    // Удаляем из CoreData
                    self.context.delete(taskToDelete)
                    
                    // Сохраняем контекст
                    self.saveContext()
                    
                    // Обновляем память только после успешного сохранения
                    DispatchQueue.main.async {
                        self.sharedState.tasks.removeAll { $0.id == task.id }
                        print("✅ Задача удалена из памяти после удаления из БД")
                    }
                } else {
                    print("❌ Задача с ID \(task.id) не найдена в базе данных для удаления")
                    
                    // Удаляем из памяти, если она там есть
                    DispatchQueue.main.async {
                        self.sharedState.tasks.removeAll { $0.id == task.id }
                        print("⚠️ Задача удалена только из памяти")
                    }
                }
            } catch {
                print("❌ Ошибка при удалении задачи: \(error)")
            }
        }
    }

    func updateTaskStartTimeKeepingEnd(_ task: TaskOnRing, newStartTime: Date) {
        guard let index = sharedState.tasks.firstIndex(where: { $0.id == task.id }) else { return }

        let calendar = Calendar.current
        
        // Создаем компоненты для новой даты, сохраняя день из selectedDate
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: newStartTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.timeZone = TimeZone.current

        guard let newStart = calendar.date(from: components) else { return }
        
        // Убираем все проверки минимальной длительности
        // Просто обновляем задачу с новым временем начала
        var updatedTask = task
        updatedTask.startTime = newStart

        // Обновляем в CoreData
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

        do {
            if let existingTask = try self.context.fetch(request).first {
                existingTask.startTime = newStart

                // Обновляем в памяти
                sharedState.tasks[index] = updatedTask

                // Сохраняем изменения
                self.saveContext()
            }
        } catch {
            print("Ошибка при обновлении времени начала задачи: \(error)")
        }
    }

    func updateTaskStartTime(_ task: TaskOnRing, newStartTime: Date) {
        let calendar = Calendar.current

        // Извлекаем компоненты нового времени
        let timeComponents = calendar.dateComponents([.hour, .minute], from: newStartTime)

        // Используем selectedDate для даты
        let selectedComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)

        // Создаем нормализованные компоненты
        var normalizedComponents = DateComponents()
        normalizedComponents.year = selectedComponents.year
        normalizedComponents.month = selectedComponents.month
        normalizedComponents.day = selectedComponents.day
        normalizedComponents.hour = timeComponents.hour
        normalizedComponents.minute = timeComponents.minute
        normalizedComponents.timeZone = TimeZone.current

        if let normalizedStartTime = calendar.date(from: normalizedComponents) {
            // Сначала найдем существующую задачу в CoreData
            let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
            request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

            do {
                if let existingTask = try self.context.fetch(request).first {
                    // Обновляем существующую задачу вместо создания новой
                    existingTask.startTime = normalizedStartTime

                    // Обновляем задачу в памяти
                    if let index = sharedState.tasks.firstIndex(where: { $0.id == task.id }) {
                        var updatedTask = task
                        updatedTask.startTime = normalizedStartTime
                        sharedState.tasks[index] = updatedTask
                    }

                    // Сохраняем изменения
                    self.saveContext()
                }
            } catch {
                print("Ошибка при обновлении времени начала задачи: \(error)")
            }
        }
    }

    func updateTaskDuration(_ task: TaskOnRing, newEndTime: Date) {
        guard let index = sharedState.tasks.firstIndex(where: { $0.id == task.id }) else { return }

        let calendar = Calendar.current

        // Создаем компоненты для новой даты окончания, используя selectedDate
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: newEndTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.timeZone = TimeZone.current

        guard let newEnd = calendar.date(from: components) else { return }
        
        // Убираем все проверки минимальной длительности
        // Просто обновляем задачу с новым временем окончания
        var updatedTask = task
        updatedTask.endTime = newEnd

        // Обновляем в CoreData
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

        do {
            if let existingTask = try self.context.fetch(request).first {
                existingTask.endTime = newEnd

                // Обновляем в памяти
                sharedState.tasks[index] = updatedTask

                // Сохраняем изменения
                self.saveContext()
            }
        } catch {
            print("Ошибка при обновлении времени окончания задачи: \(error)")
        }
    }

    private func validateTimeInterval(_ interval: TimeInterval) -> TimeInterval {
        guard interval.isFinite else { return 0 }
        return max(0, min(interval, 24 * 60 * 60))  // Максимум 24 часа
    }

    private func validateTask(_ task: TaskOnRing) -> Bool {
        // Убираем все проверки - всегда возвращаем true
        return true
    }

    func createTask(startTime: Date, endTime: Date, category: TaskCategoryModel) async throws {
        // Убираем все проверки корректности и минимальной длительности
        let calendar = Calendar.current

        // Нормализуем время начала
        let startComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: startTime
        )

        var normalizedStartComponents = DateComponents()
        normalizedStartComponents.year = startComponents.year
        normalizedStartComponents.month = startComponents.month
        normalizedStartComponents.day = startComponents.day
        normalizedStartComponents.hour = startComponents.hour
        normalizedStartComponents.minute = startComponents.minute
        normalizedStartComponents.timeZone = TimeZone.current

        // Нормализуем время окончания
        let endComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: endTime
        )

        var normalizedEndComponents = DateComponents()
        normalizedEndComponents.year = endComponents.year
        normalizedEndComponents.month = endComponents.month
        normalizedEndComponents.day = endComponents.day
        normalizedEndComponents.hour = endComponents.hour
        normalizedEndComponents.minute = endComponents.minute
        normalizedEndComponents.timeZone = TimeZone.current

        // Убираем проверку на ошибку нормализации
        let normalizedStartTime = calendar.date(from: normalizedStartComponents) ?? startTime
        let normalizedEndTime = calendar.date(from: normalizedEndComponents) ?? endTime

        let newTask = TaskOnRing(
            id: UUID(),
            startTime: normalizedStartTime,
            endTime: normalizedEndTime,
            color: category.color,
            icon: category.iconName,
            category: category,
            isCompleted: false
        )

        addTask(newTask)
    }

    func updateTask(_ task: TaskOnRing, newStartTime: Date?, newEndTime: Date?) async throws {
        let calendar = Calendar.current
        var updatedTask = task

        if let newStartTime = newStartTime {
            // Нормализуем новое время начала
            var startComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute], from: newStartTime)
            startComponents.timeZone = TimeZone.current

            if let normalizedStartTime = calendar.date(from: startComponents) {
                updatedTask.startTime = normalizedStartTime
            }
        }

        if let newEndTime = newEndTime {
            // Нормализуем новое время окончания
            var endComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute], from: newEndTime)
            endComponents.timeZone = TimeZone.current

            if let normalizedEndTime = calendar.date(from: endComponents) {
                updatedTask.endTime = normalizedEndTime
            }
        }

        // Убираем все проверки валидности времени и минимальной длительности

        // Обновляем задачу в CoreData
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "id == %@", updatedTask.id as CVarArg)

        do {
            if let existingTask = try self.context.fetch(request).first {
                existingTask.startTime = updatedTask.startTime
                existingTask.endTime = updatedTask.endTime
                existingTask.isCompleted = updatedTask.isCompleted

                // Обновляем категорию если необходимо
                let categoryRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
                categoryRequest.predicate = NSPredicate(
                    format: "id == %@", updatedTask.category.id as CVarArg)
                if let category = try self.context.fetch(categoryRequest).first {
                    existingTask.category = category
                }

                // Обновляем задачу в sharedState
                if let index = sharedState.tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                    sharedState.tasks[index] = updatedTask
                }

                saveContext()
            }
        } catch {
            // Убираем выбрасывание ошибки, просто логируем
            print("Ошибка обновления задачи: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helper Methods
    
    private func normalizeTask(_ task: TaskOnRing) -> TaskOnRing {
        let calendar = Calendar.current
        
        // Нормализуем время начала
        let startComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute], 
            from: task.startTime
        )
        let normalizedStartTime = calendar.date(from: startComponents) ?? task.startTime
        
        // Нормализуем время окончания 
        let endComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute], 
            from: task.endTime
        )
        let normalizedEndTime = calendar.date(from: endComponents) ?? task.endTime
        
        var normalizedTask = task
        normalizedTask.startTime = normalizedStartTime
        normalizedTask.endTime = normalizedEndTime
        
        return normalizedTask
    }
    
    private func updateTaskCategory(_ taskEntity: TaskEntity, with category: TaskCategoryModel) {
        let categoryRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        categoryRequest.predicate = NSPredicate(format: "id == %@", category.id as CVarArg)
        
        do {
            if let categoryEntity = try self.context.fetch(categoryRequest).first {
                taskEntity.category = categoryEntity
            } else {
                // Создаем категорию, если она не существует
                let newCategoryEntity = CategoryEntity.from(category, context: self.context)
                taskEntity.category = newCategoryEntity
                print("⚠️ Создана новая категория при обновлении задачи")
            }
        } catch {
            print("❌ Ошибка при обновлении категории задачи: \(error)")
        }
    }
    
    private func saveContext() {
        guard self.context.hasChanges else { 
            print("💾 Нет изменений для сохранения")
            return 
        }
        
        do {
            try self.context.save()
            print("✅ Контекст успешно сохранен")
        } catch {
            print("❌ Ошибка сохранения контекста: \(error)")
            
            // Откатываем изменения при ошибке
            self.context.rollback()
            print("🔄 Изменения откачены")
        }
    }

    // Новый метод для обновления всей задачи
    func updateWholeTask(_ task: TaskOnRing, newStartTime: Date, newEndTime: Date) {
        guard let index = sharedState.tasks.firstIndex(where: { $0.id == task.id }) else { return }

        let calendar = Calendar.current
        
        // Создаем компоненты для новых времен, сохраняя день из selectedDate
        var startComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let startTimeComponents = calendar.dateComponents([.hour, .minute], from: newStartTime)
        startComponents.hour = startTimeComponents.hour
        startComponents.minute = startTimeComponents.minute
        startComponents.timeZone = TimeZone.current

        var endComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let endTimeComponents = calendar.dateComponents([.hour, .minute], from: newEndTime)
        endComponents.hour = endTimeComponents.hour
        endComponents.minute = endTimeComponents.minute
        endComponents.timeZone = TimeZone.current

        guard let newStart = calendar.date(from: startComponents),
              let newEnd = calendar.date(from: endComponents) else { return }
        
        // Обновляем задачу
        var updatedTask = task
        updatedTask.startTime = newStart
        updatedTask.endTime = newEnd

        // Обновляем в CoreData
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

        do {
            if let existingTask = try self.context.fetch(request).first {
                existingTask.startTime = newStart
                existingTask.endTime = newEnd

                // Обновляем в памяти
                sharedState.tasks[index] = updatedTask

                // Сохраняем изменения
                self.saveContext()
            }
        } catch {
            print("Ошибка при обновлении всей задачи: \(error)")
        }
    }
}
