import CoreData
import Foundation
import SwiftUI
import Combine

// MARK: - Task Management Protocol
@MainActor
protocol TaskManagementProtocol: AnyObject {
    // MARK: - Properties
    var selectedDate: Date { get set }
    
    // MARK: - Basic CRUD Operations
    func addTask(_ task: TaskOnRing)
    func updateTask(_ task: TaskOnRing)
    func removeTask(_ task: TaskOnRing)
    func fetchTasks()
    
    // MARK: - Time-specific Updates
    func updateTaskStartTimeKeepingEnd(_ task: TaskOnRing, newStartTime: Date)
    func updateTaskStartTime(_ task: TaskOnRing, newStartTime: Date)
    func updateTaskDuration(_ task: TaskOnRing, newEndTime: Date)
    func updateWholeTask(_ task: TaskOnRing, newStartTime: Date, newEndTime: Date)
    
    // MARK: - Async Operations
    func createTask(startTime: Date, endTime: Date, category: TaskCategoryModel) async throws
    func updateTask(_ task: TaskOnRing, newStartTime: Date?, newEndTime: Date?) async throws
    func removeTask(_ task: TaskOnRing) async throws
    
    // MARK: - Batch Operations
    func updateMultipleTasks(_ updates: [(TaskOnRing, Date, Date)]) async throws
    func removeMultipleTasks(_ tasks: [TaskOnRing]) async throws
    
    // MARK: - Task Filtering and Querying
    func getTasksForDate(_ date: Date) -> [TaskOnRing]
    func getTasksInTimeRange(from startTime: Date, to endTime: Date) -> [TaskOnRing]
    func getActiveTask(at time: Date) -> TaskOnRing?
    func getTasksByCategory(_ category: TaskCategoryModel) -> [TaskOnRing]
    
    // MARK: - Data Persistence
    func saveChanges() throws
    func discardChanges()
    func hasUnsavedChanges() -> Bool
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let taskManagementDidUpdateTasks = Notification.Name("TaskManagementDidUpdateTasks")
    static let taskManagementDidAddTask = Notification.Name("TaskManagementDidAddTask")
    static let taskManagementDidRemoveTask = Notification.Name("TaskManagementDidRemoveTask")
}

// MARK: - Updated TaskManagement Implementation
@available(iOS 13.0, *)
@MainActor
class TaskManagement: TaskManagementProtocol {
    // MARK: - Properties
    private let context: NSManagedObjectContext
    private let sharedState: SharedStateService
    private let operationQueue = DispatchQueue(label: "taskManagement.queue", qos: .userInitiated)
    
    var selectedDate: Date {
        didSet {
            NotificationCenter.default.post(
                name: .taskManagementSelectedDateChanged,
                object: self,
                userInfo: ["newDate": selectedDate, "oldDate": oldValue]
            )
        }
    }

    init(sharedState: SharedStateService, selectedDate: Date) {
        self.sharedState = sharedState
        self.context = sharedState.context
        self.selectedDate = selectedDate
        fetchTasks()
    }

    // MARK: - Basic CRUD Operations

    func fetchTasks() {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
            
            do {
                let taskEntities = try self.context.fetch(request)
                let fetchedTasks = taskEntities.map { $0.taskModel }
                
                DispatchQueue.main.async {
                    self.sharedState.tasks = fetchedTasks
                    
                    NotificationCenter.default.post(
                        name: .taskManagementDidUpdateTasks,
                        object: self,
                        userInfo: ["tasks": fetchedTasks]
                    )
                }
            } catch {
                self.handleError(error, operation: "fetchTasks")
            }
        }
    }

    func addTask(_ task: TaskOnRing) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            let normalizedTask = self.normalizeTask(task)
            _ = TaskEntity.from(normalizedTask, context: self.context)
            
            do {
                try self.saveContext()
            
                DispatchQueue.main.async {
                    self.sharedState.tasks.append(normalizedTask)
                        
                    NotificationCenter.default.post(
                        name: .taskManagementDidAddTask,
                        object: self,
                        userInfo: ["task": normalizedTask]
                    )
                }
            } catch {
                self.handleError(error, operation: "addTask")
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
                    
                    existingTask.startTime = normalizedTask.startTime
                    existingTask.endTime = normalizedTask.endTime
                    existingTask.isCompleted = normalizedTask.isCompleted
                    self.updateTaskCategory(existingTask, with: normalizedTask.category)
                    
                    try self.saveContext()
                    
                    DispatchQueue.main.async {
                        if let index = self.sharedState.tasks.firstIndex(where: { $0.id == task.id }) {
                            self.sharedState.tasks[index] = normalizedTask
                        }
                    }
                }
            } catch {
                self.handleError(error, operation: "updateTask")
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
                    self.context.delete(taskToDelete)
                    try self.saveContext()
                    
                    DispatchQueue.main.async {
                        self.sharedState.tasks.removeAll { $0.id == task.id }
                        
                        NotificationCenter.default.post(
                            name: .taskManagementDidRemoveTask,
                            object: self,
                            userInfo: ["task": task]
                        )
                    }
                }
            } catch {
                self.handleError(error, operation: "removeTask")
            }
        }
    }

    // MARK: - Time-specific Updates

    func updateTaskStartTimeKeepingEnd(_ task: TaskOnRing, newStartTime: Date) {
        guard let index = sharedState.tasks.firstIndex(where: { $0.id == task.id }) else { return }

        let calendar = Calendar.current
        
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: newStartTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.timeZone = TimeZone.current

        guard let newStart = calendar.date(from: components) else { return }
        
        var updatedTask = task
        updatedTask.startTime = newStart

        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

        do {
            if let existingTask = try self.context.fetch(request).first {
                existingTask.startTime = newStart
                sharedState.tasks[index] = updatedTask
                try self.saveContext()
            }
        } catch {
            handleError(error, operation: "updateTaskStartTimeKeepingEnd")
        }
    }

    func updateTaskStartTime(_ task: TaskOnRing, newStartTime: Date) {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: newStartTime)
        let selectedComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)

        var normalizedComponents = DateComponents()
        normalizedComponents.year = selectedComponents.year
        normalizedComponents.month = selectedComponents.month
        normalizedComponents.day = selectedComponents.day
        normalizedComponents.hour = timeComponents.hour
        normalizedComponents.minute = timeComponents.minute
        normalizedComponents.timeZone = TimeZone.current

        if let normalizedStartTime = calendar.date(from: normalizedComponents) {
            let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
            request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

            do {
                if let existingTask = try self.context.fetch(request).first {
                    existingTask.startTime = normalizedStartTime

                    if let index = sharedState.tasks.firstIndex(where: { $0.id == task.id }) {
                        var updatedTask = task
                        updatedTask.startTime = normalizedStartTime
                        sharedState.tasks[index] = updatedTask
                    }

                    try self.saveContext()
                }
            } catch {
                handleError(error, operation: "updateTaskStartTime")
            }
        }
    }

    func updateTaskDuration(_ task: TaskOnRing, newEndTime: Date) {
        guard let index = sharedState.tasks.firstIndex(where: { $0.id == task.id }) else { return }

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: newEndTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.timeZone = TimeZone.current

        guard let newEnd = calendar.date(from: components) else { return }
        
        var updatedTask = task
        updatedTask.endTime = newEnd

        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

        do {
            if let existingTask = try self.context.fetch(request).first {
                existingTask.endTime = newEnd
                sharedState.tasks[index] = updatedTask
                try self.saveContext()
            }
        } catch {
            handleError(error, operation: "updateTaskDuration")
        }
    }
    
    func updateWholeTask(_ task: TaskOnRing, newStartTime: Date, newEndTime: Date) {
        guard let index = sharedState.tasks.firstIndex(where: { $0.id == task.id }) else { return }

        let calendar = Calendar.current
        
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
        
        var updatedTask = task
        updatedTask.startTime = newStart
        updatedTask.endTime = newEnd

        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

        do {
            if let existingTask = try self.context.fetch(request).first {
                existingTask.startTime = newStart
                existingTask.endTime = newEnd
                sharedState.tasks[index] = updatedTask
                try self.saveContext()
            }
        } catch {
            handleError(error, operation: "updateWholeTask")
        }
    }

    // MARK: - Async Operations

    func createTask(startTime: Date, endTime: Date, category: TaskCategoryModel) async throws {
        let newTask = TaskOnRing(
            id: UUID(),
            startTime: startTime,
            endTime: endTime,
            color: category.color,
            icon: category.iconName,
            category: category,
            isCompleted: false
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = newTask
            operationQueue.async { [weak self] in
                guard let self = self else { 
                    continuation.resume(throwing: TaskManagementError.operationFailed)
                    return 
                }
                
                Task { @MainActor in
                    self.addTask(task)
                    continuation.resume()
                }
            }
        }
    }

    func updateTask(_ task: TaskOnRing, newStartTime: Date?, newEndTime: Date?) async throws {
        var updatedTask = task

        if let newStartTime = newStartTime {
            updatedTask.startTime = newStartTime
        }

        if let newEndTime = newEndTime {
            updatedTask.endTime = newEndTime
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = updatedTask
            operationQueue.async { [weak self] in
                guard let self = self else { 
                    continuation.resume(throwing: TaskManagementError.operationFailed)
                    return 
                }
                
                Task { @MainActor in
                    self.updateTask(task)
                    continuation.resume()
                }
            }
        }
    }
    
    func removeTask(_ task: TaskOnRing) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let taskToRemove = task
            operationQueue.async { [weak self] in
                guard let self = self else { 
                    continuation.resume(throwing: TaskManagementError.operationFailed)
                    return 
                }
                
                Task { @MainActor in
                    self.removeTask(taskToRemove)
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Batch Operations
    
    func updateMultipleTasks(_ updates: [(TaskOnRing, Date, Date)]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let tasksToUpdate = updates
            operationQueue.async { [weak self] in
                guard let self = self else { 
                    continuation.resume(throwing: TaskManagementError.operationFailed)
                    return 
                }
                
                do {
                    for (task, newStart, newEnd) in tasksToUpdate {
                        var updatedTask = task
                        updatedTask.startTime = newStart
                        updatedTask.endTime = newEnd
                        Task { @MainActor in
                            self.updateTask(updatedTask)
                        }
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func removeMultipleTasks(_ tasks: [TaskOnRing]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let tasksToRemove = tasks
            operationQueue.async { [weak self] in
                guard let self = self else { 
                    continuation.resume(throwing: TaskManagementError.operationFailed)
                    return 
                }
                
                Task { @MainActor in
                    for task in tasksToRemove {
                        self.removeTask(task)
                    }
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Task Filtering and Querying
    
    func getTasksForDate(_ date: Date) -> [TaskOnRing] {
        return sharedState.tasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: date)
        }
    }
    
    func getTasksInTimeRange(from startTime: Date, to endTime: Date) -> [TaskOnRing] {
        return sharedState.tasks.filter { task in
            task.startTime < endTime && task.endTime > startTime
        }
    }
    
    func getActiveTask(at time: Date) -> TaskOnRing? {
        return sharedState.tasks.first { task in
            task.startTime <= time && task.endTime > time
        }
    }
    
    func getTasksByCategory(_ category: TaskCategoryModel) -> [TaskOnRing] {
        return sharedState.tasks.filter { $0.category == category }
    }

    // MARK: - Data Persistence
    
    func saveChanges() throws {
        try saveContext()
    }
    
    func discardChanges() {
        context.rollback()
    }
    
    func hasUnsavedChanges() -> Bool {
        return context.hasChanges
    }

    // MARK: - Private Helper Methods
    
    private func normalizeTask(_ task: TaskOnRing) -> TaskOnRing {
        let calendar = Calendar.current
        
        let startComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute], 
            from: task.startTime
        )
        let normalizedStartTime = calendar.date(from: startComponents) ?? task.startTime
        
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
                let newCategoryEntity = CategoryEntity.from(category, context: self.context)
                taskEntity.category = newCategoryEntity
                #if DEBUG
                NSLog("Created new category while updating task")
                #endif
            }
        } catch {
                            #if DEBUG
                NSLog("Error updating task category: \(error.localizedDescription)")
                #endif
        }
    }
    
    private func saveContext() throws {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            context.rollback()
            throw TaskManagementError.saveFailed(error)
        }
    }
    
    private func handleError(_ error: Error, operation: String) {
        #if DEBUG
        NSLog("Error in operation \(operation): \(error.localizedDescription)")
        #endif
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .taskManagementErrorOccurred,
                object: self,
                userInfo: ["error": error, "operation": operation]
            )
        }
    }
}

// MARK: - Error Types
enum TaskManagementError: LocalizedError {
    case operationFailed
    case saveFailed(Error)
    case taskNotFound(UUID)
    
    var errorDescription: String? {
        switch self {
        case .operationFailed:
            return "Операция не выполнена"
        case .saveFailed(let error):
            return "Ошибка сохранения: \(error.localizedDescription)"
        case .taskNotFound(let id):
            return "Задача с ID \(id) не найдена"
        }
    }
}

// MARK: - Additional Notification Names
extension Notification.Name {
    static let taskManagementSelectedDateChanged = Notification.Name("TaskManagementSelectedDateChanged")
    static let taskManagementErrorOccurred = Notification.Name("TaskManagementErrorOccurred")
}

