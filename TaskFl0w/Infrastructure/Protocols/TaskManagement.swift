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
    
    // MARK: - Validation and Overlap Management
    func validateTaskTime(_ task: TaskOnRing) -> TaskValidationResult
    func findTaskOverlaps(for task: TaskOnRing, excluding excludedTasks: [TaskOnRing]) -> [TaskOnRing]
    func resolveTaskOverlaps(for task: TaskOnRing, strategy: OverlapResolutionStrategy) -> [TaskOnRing]
    
    // MARK: - Time Slot Management
    func findFreeTimeSlot(duration: TimeInterval, preferredStartTime: Date, on date: Date) -> TimeSlot?
    func getAvailableTimeSlots(duration: TimeInterval, on date: Date) -> [TimeSlot]
    
    // MARK: - Task Filtering and Querying
    func getTasksForDate(_ date: Date) -> [TaskOnRing]
    func getTasksInTimeRange(from startTime: Date, to endTime: Date) -> [TaskOnRing]
    func getActiveTask(at time: Date) -> TaskOnRing?
    func getTasksByCategory(_ category: TaskCategoryModel) -> [TaskOnRing]
    
    // MARK: - Statistics and Analytics
    func getTaskStatistics(for date: Date) -> TaskStatistics
    func getCategoryStatistics(for date: Date) -> [TaskCategoryModel: CategoryStatistics]
    
    // MARK: - Data Persistence
    func saveChanges() throws
    func discardChanges()
    func hasUnsavedChanges() -> Bool
}

// MARK: - Supporting Types

struct TaskValidationResult {
    let isValid: Bool
    let errors: [TaskValidationError]
    let warnings: [TaskValidationWarning]
}

enum TaskValidationError: LocalizedError {
    case invalidTimeRange
    case taskTooShort(minimumDuration: TimeInterval)
    case taskTooLong(maximumDuration: TimeInterval)
    case timeOutOfBounds(validRange: ClosedRange<Date>)
    case overlapWithExistingTask(conflictingTask: TaskOnRing)
    
    var errorDescription: String? {
        switch self {
        case .invalidTimeRange:
            return "Время окончания должно быть позже времени начала"
        case .taskTooShort(let minimum):
            return "Задача слишком короткая. Минимальная длительность: \(Int(minimum/60)) минут"
        case .taskTooLong(let maximum):
            return "Задача слишком длинная. Максимальная длительность: \(Int(maximum/3600)) часов"
        case .timeOutOfBounds(let range):
            return "Время должно быть в пределах от \(range.lowerBound) до \(range.upperBound)"
        case .overlapWithExistingTask(let task):
            return "Перекрытие с существующей задачей: \(task.category.rawValue)"
        }
    }
}

enum TaskValidationWarning {
    case minorOverlap(with: TaskOnRing, duration: TimeInterval)
    case shortTask(duration: TimeInterval)
    case lateNightTask
    case earlyMorningTask
    
    var description: String {
        switch self {
        case .minorOverlap(let task, let duration):
            return "Небольшое перекрытие (\(Int(duration/60)) мин) с задачей: \(task.category.rawValue)"
        case .shortTask(let duration):
            return "Короткая задача (\(Int(duration/60)) мин)"
        case .lateNightTask:
            return "Поздняя задача (после 22:00)"
        case .earlyMorningTask:
            return "Ранняя задача (до 6:00)"
        }
    }
}

enum OverlapResolutionStrategy {
    case moveConflictingTasks
    case shrinkConflictingTasks
    case findAlternativeSlot
    case splitConflictingTasks
    case manual // Требует ручного разрешения
}

struct TimeSlot {
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    
    var isValid: Bool {
        return endTime > startTime && duration > 0
    }
}

struct TaskStatistics {
    let totalTasks: Int
    let completedTasks: Int
    let totalDuration: TimeInterval
    let completedDuration: TimeInterval
    let averageTaskDuration: TimeInterval
    let categoryDistribution: [TaskCategoryModel: Int]
    let busyPercentage: Double
    let freeTimeSlots: [TimeSlot]
}

struct CategoryStatistics {
    let taskCount: Int
    let totalDuration: TimeInterval
    let averageDuration: TimeInterval
    let completionRate: Double
    let peakUsageTime: Date?
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let taskManagementDidUpdateTasks = Notification.Name("TaskManagementDidUpdateTasks")
    static let taskManagementDidAddTask = Notification.Name("TaskManagementDidAddTask")
    static let taskManagementDidRemoveTask = Notification.Name("TaskManagementDidRemoveTask")
    static let taskManagementDidResolveOverlaps = Notification.Name("TaskManagementDidResolveOverlaps")
    static let taskManagementValidationFailed = Notification.Name("TaskManagementValidationFailed")
}

// MARK: - Updated TaskManagement Implementation
@available(iOS 13.0, *)
@MainActor
class TaskManagement: TaskManagementProtocol {
    // MARK: - Properties
    private let context: NSManagedObjectContext
    private let sharedState: SharedStateService
    private let operationQueue = DispatchQueue(label: "taskManagement.queue", qos: .userInitiated)
    private let validator = TaskValidator()
    private let overlapResolver = TaskOverlapResolver()
    
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
        Task {
            do {
                try await createTask(
                    startTime: task.startTime,
                    endTime: task.endTime,
                    category: task.category
                )
            } catch {
                handleError(error, operation: "addTask")
            }
        }
    }

    func updateTask(_ task: TaskOnRing) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            let validationResult = self.validator.validate(task)
            guard validationResult.isValid else {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .taskManagementValidationFailed,
                        object: self,
                        userInfo: ["task": task, "errors": validationResult.errors]
                    )
                }
                return
            }
            
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
        
        // Создаем компоненты для новой даты, сохраняя день из selectedDate
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: newStartTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.timeZone = TimeZone.current

        guard let newStart = calendar.date(from: components) else { return }
        
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
                try self.saveContext()
            }
        } catch {
            handleError(error, operation: "updateTaskStartTimeKeepingEnd")
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
            // Находим существующую задачу в CoreData
            let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
            request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

            do {
                if let existingTask = try self.context.fetch(request).first {
                    existingTask.startTime = normalizedStartTime

                    // Обновляем задачу в памяти
                    if let index = sharedState.tasks.firstIndex(where: { $0.id == task.id }) {
                        var updatedTask = task
                        updatedTask.startTime = normalizedStartTime
                        sharedState.tasks[index] = updatedTask
                    }

                    // Сохраняем изменения
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

        // Создаем компоненты для новой даты окончания, используя selectedDate
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: newEndTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.timeZone = TimeZone.current

        guard let newEnd = calendar.date(from: components) else { return }
        
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
                try self.saveContext()
            }
        } catch {
            handleError(error, operation: "updateTaskDuration")
        }
    }
    
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

        let validationResult = validator.validate(newTask)
        guard validationResult.isValid else {
            throw TaskManagementError.validationFailed(validationResult.errors)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = newTask
            operationQueue.async { [weak self] in
                guard let self = self else { 
                    continuation.resume(throwing: TaskManagementError.operationFailed)
                    return 
                }
                
                do {
                    // Создаем сущность задачи
                    _ = TaskEntity.from(task, context: self.context)
                    
                    // Сохраняем контекст
                    try self.saveContext()
                    
                    // Обновляем состояние
                    DispatchQueue.main.async {
                        self.sharedState.tasks.append(task)
                        
                        NotificationCenter.default.post(
                            name: .taskManagementDidAddTask,
                            object: self,
                            userInfo: ["task": task]
                        )
                        
                        continuation.resume()
                    }
                } catch {
                    continuation.resume(throwing: TaskManagementError.saveFailed(error))
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
        
        let validationResult = validator.validate(updatedTask)
        guard validationResult.isValid else {
            throw TaskManagementError.validationFailed(validationResult.errors)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = updatedTask // Capture the task locally
            operationQueue.async { [weak self] in
                guard let self = self else { 
                    continuation.resume(throwing: TaskManagementError.operationFailed)
                    return 
                }
                
                self.updateTask(task)
                continuation.resume()
            }
        }
    }
    
    func removeTask(_ task: TaskOnRing) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let taskToRemove = task // Capture the task locally
            operationQueue.async { [weak self] in
                guard let self = self else { 
                    continuation.resume(throwing: TaskManagementError.operationFailed)
                    return 
                }
                
                self.removeTask(taskToRemove)
                continuation.resume()
            }
        }
    }

    // MARK: - Batch Operations
    
    func updateMultipleTasks(_ updates: [(TaskOnRing, Date, Date)]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let tasksToUpdate = updates // Capture the updates locally
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
                        
                        let validationResult = self.validator.validate(updatedTask)
                        guard validationResult.isValid else {
                            throw TaskManagementError.validationFailed(validationResult.errors)
                        }
                        
                        self.updateTask(updatedTask)
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
            let tasksToRemove = tasks // Capture the tasks locally
            operationQueue.async { [weak self] in
                guard let self = self else { 
                    continuation.resume(throwing: TaskManagementError.operationFailed)
                    return 
                }
                
                for task in tasksToRemove {
                    self.removeTask(task)
                }
                
                continuation.resume()
            }
        }
    }

    // MARK: - Validation and Overlap Management
    
    func validateTaskTime(_ task: TaskOnRing) -> TaskValidationResult {
        return validator.validate(task)
    }
    
    func findTaskOverlaps(for task: TaskOnRing, excluding excludedTasks: [TaskOnRing]) -> [TaskOnRing] {
        let allTasks = sharedState.tasks.filter { existingTask in
            existingTask.id != task.id && !excludedTasks.contains { $0.id == existingTask.id }
        }
        
        return allTasks.filter { existingTask in
            task.startTime < existingTask.endTime && task.endTime > existingTask.startTime
        }
    }
    
    func resolveTaskOverlaps(for task: TaskOnRing, strategy: OverlapResolutionStrategy) -> [TaskOnRing] {
        return overlapResolver.resolve(task: task, strategy: strategy, allTasks: sharedState.tasks)
    }

    // MARK: - Time Slot Management
    
    func findFreeTimeSlot(duration: TimeInterval, preferredStartTime: Date, on date: Date) -> TimeSlot? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-60)
        
        let dayTasks = getTasksForDate(date).sorted { $0.startTime < $1.startTime }
        
        // Проверяем предпочтительное время
        let preferredEndTime = preferredStartTime.addingTimeInterval(duration)
        if isTimeSlotFree(start: preferredStartTime, end: preferredEndTime, tasks: dayTasks) {
            return TimeSlot(startTime: preferredStartTime, endTime: preferredEndTime, duration: duration)
        }
        
        // Ищем ближайший свободный слот
        return findNearestFreeTimeSlot(duration: duration, preferredStart: preferredStartTime, 
                                     dayStart: startOfDay, dayEnd: endOfDay, tasks: dayTasks)
    }
    
    func getAvailableTimeSlots(duration: TimeInterval, on date: Date) -> [TimeSlot] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-60)
        
        let dayTasks = getTasksForDate(date).sorted { $0.startTime < $1.startTime }
        var availableSlots: [TimeSlot] = []
        
        var currentTime = startOfDay
        
        for task in dayTasks {
            if task.startTime.timeIntervalSince(currentTime) >= duration {
                let slot = TimeSlot(startTime: currentTime, endTime: task.startTime, 
                                  duration: task.startTime.timeIntervalSince(currentTime))
                availableSlots.append(slot)
            }
            currentTime = max(currentTime, task.endTime)
        }
        
        // Проверяем время после последней задачи
        if endOfDay.timeIntervalSince(currentTime) >= duration {
            let slot = TimeSlot(startTime: currentTime, endTime: endOfDay, 
                              duration: endOfDay.timeIntervalSince(currentTime))
            availableSlots.append(slot)
        }
        
        return availableSlots
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

    // MARK: - Statistics and Analytics
    
    func getTaskStatistics(for date: Date) -> TaskStatistics {
        let dayTasks = getTasksForDate(date)
        let completedTasks = dayTasks.filter { $0.isCompleted }
        
        let totalDuration = dayTasks.reduce(0) { $0 + $1.duration }
        let completedDuration = completedTasks.reduce(0) { $0 + $1.duration }
        let averageDuration = dayTasks.isEmpty ? 0 : totalDuration / Double(dayTasks.count)
        
        let categoryDistribution = Dictionary(grouping: dayTasks) { $0.category }
            .mapValues { $0.count }
        
        let busyPercentage = (totalDuration / (24 * 60 * 60)) * 100
        let freeSlots = getAvailableTimeSlots(duration: 15 * 60, on: date) // 15-минутные слоты
        
        return TaskStatistics(
            totalTasks: dayTasks.count,
            completedTasks: completedTasks.count,
            totalDuration: totalDuration,
            completedDuration: completedDuration,
            averageTaskDuration: averageDuration,
            categoryDistribution: categoryDistribution,
            busyPercentage: busyPercentage,
            freeTimeSlots: freeSlots
        )
    }
    
    func getCategoryStatistics(for date: Date) -> [TaskCategoryModel: CategoryStatistics] {
        let dayTasks = getTasksForDate(date)
        let groupedTasks = Dictionary(grouping: dayTasks) { $0.category }
        
        return groupedTasks.mapValues { tasks in
            let completedTasks = tasks.filter { $0.isCompleted }
            let totalDuration = tasks.reduce(0) { $0 + $1.duration }
            let averageDuration = totalDuration / Double(tasks.count)
            let completionRate = Double(completedTasks.count) / Double(tasks.count)
            
            // Находим пиковое время использования
            let peakUsageTime = tasks.max { $0.duration < $1.duration }?.startTime
            
            return CategoryStatistics(
                taskCount: tasks.count,
                totalDuration: totalDuration,
                averageDuration: averageDuration,
                completionRate: completionRate,
                peakUsageTime: peakUsageTime
            )
        }
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
        print("❌ Ошибка в операции \(operation): \(error)")
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .taskManagementErrorOccurred,
                object: self,
                userInfo: ["error": error, "operation": operation]
            )
        }
    }
    
    private func isTimeSlotFree(start: Date, end: Date, tasks: [TaskOnRing]) -> Bool {
        return !tasks.contains { task in
            start < task.endTime && end > task.startTime
        }
    }
    
    private func findNearestFreeTimeSlot(duration: TimeInterval, preferredStart: Date, 
                                       dayStart: Date, dayEnd: Date, tasks: [TaskOnRing]) -> TimeSlot? {
        let searchStep: TimeInterval = 15 * 60 // 15 минут
        let maxSearchRadius: TimeInterval = 12 * 60 * 60 // 12 часов
        
        // Поиск в радиусе предпочтительного времени
        for offset in stride(from: searchStep, to: maxSearchRadius, by: searchStep) {
            // Справа от предпочтительного времени
            let rightStartTime = preferredStart.addingTimeInterval(offset)
            let rightEndTime = rightStartTime.addingTimeInterval(duration)
            
            if rightEndTime <= dayEnd && isTimeSlotFree(start: rightStartTime, end: rightEndTime, tasks: tasks) {
                return TimeSlot(startTime: rightStartTime, endTime: rightEndTime, duration: duration)
            }
            
            // Слева от предпочтительного времени
            let leftStartTime = preferredStart.addingTimeInterval(-offset)
            let leftEndTime = leftStartTime.addingTimeInterval(duration)
            
            if leftStartTime >= dayStart && isTimeSlotFree(start: leftStartTime, end: leftEndTime, tasks: tasks) {
                return TimeSlot(startTime: leftStartTime, endTime: leftEndTime, duration: duration)
            }
        }
        
        // Если не найдено в радиусе, ищем первое доступное место
        if tasks.isEmpty {
            let startTime = max(dayStart, preferredStart)
            let endTime = startTime.addingTimeInterval(duration)
            if endTime <= dayEnd {
                return TimeSlot(startTime: startTime, endTime: endTime, duration: duration)
            }
        }
        
        // Ищем промежутки между задачами
        let sortedTasks = tasks.sorted { $0.startTime < $1.startTime }
        
        // Проверяем место перед первой задачей
        if let firstTask = sortedTasks.first,
           firstTask.startTime.timeIntervalSince(dayStart) >= duration {
            let endTime = firstTask.startTime
            let startTime = endTime.addingTimeInterval(-duration)
            if startTime >= dayStart {
                return TimeSlot(startTime: startTime, endTime: endTime, duration: duration)
            }
        }
        
        // Ищем промежутки между задачами
        for i in 0..<(sortedTasks.count - 1) {
            let currentTaskEnd = sortedTasks[i].endTime
            let nextTaskStart = sortedTasks[i + 1].startTime
            let availableTime = nextTaskStart.timeIntervalSince(currentTaskEnd)
            
            if availableTime >= duration {
                return TimeSlot(startTime: currentTaskEnd, endTime: currentTaskEnd.addingTimeInterval(duration), duration: duration)
            }
        }
        
        // Проверяем место после последней задачи
        if let lastTask = sortedTasks.last {
            let availableTime = dayEnd.timeIntervalSince(lastTask.endTime)
            if availableTime >= duration {
                return TimeSlot(startTime: lastTask.endTime, endTime: lastTask.endTime.addingTimeInterval(duration), duration: duration)
            }
        }
        
        return nil
    }
}

// MARK: - Error Types
enum TaskManagementError: LocalizedError {
    case validationFailed([TaskValidationError])
    case operationFailed
    case saveFailed(Error)
    case taskNotFound(UUID)
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let errors):
            return "Ошибки валидации: \(errors.map { $0.localizedDescription }.joined(separator: ", "))"
        case .operationFailed:
            return "Операция не выполнена"
        case .saveFailed(let error):
            return "Ошибка сохранения: \(error.localizedDescription)"
        case .taskNotFound(let id):
            return "Задача с ID \(id) не найдена"
        }
    }
}

// MARK: - Helper Classes
class TaskValidator {
    func validate(_ task: TaskOnRing) -> TaskValidationResult {
        var errors: [TaskValidationError] = []
        var warnings: [TaskValidationWarning] = []
        
        // Проверка валидности временного диапазона
        if task.endTime <= task.startTime {
            errors.append(.invalidTimeRange)
        }
        
        // Проверка минимальной длительности
        let duration = task.duration
        if duration < 60 { // Меньше 1 минуты
            errors.append(.taskTooShort(minimumDuration: 60))
        } else if duration < 15 * 60 { // Меньше 15 минут
            warnings.append(.shortTask(duration: duration))
        }
        
        // Проверка максимальной длительности
        if duration > 12 * 60 * 60 { // Больше 12 часов
            errors.append(.taskTooLong(maximumDuration: 12 * 60 * 60))
        }
        
        // Проверка времени (поздние/ранние задачи)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: task.startTime)
        
        if hour >= 22 {
            warnings.append(.lateNightTask)
        } else if hour < 6 {
            warnings.append(.earlyMorningTask)
        }
        
        return TaskValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
}

class TaskOverlapResolver {
    func resolve(task: TaskOnRing, strategy: OverlapResolutionStrategy, allTasks: [TaskOnRing]) -> [TaskOnRing] {
        switch strategy {
        case .moveConflictingTasks:
            return moveConflictingTasks(for: task, in: allTasks)
        case .shrinkConflictingTasks:
            return shrinkConflictingTasks(for: task, in: allTasks)
        case .findAlternativeSlot:
            return findAlternativeSlot(for: task, in: allTasks)
        case .splitConflictingTasks:
            return splitConflictingTasks(for: task, in: allTasks)
        case .manual:
            return [] // Требует ручного разрешения
        }
    }
    
    private func moveConflictingTasks(for task: TaskOnRing, in allTasks: [TaskOnRing]) -> [TaskOnRing] {
        // Реализация перемещения конфликтующих задач
        return []
    }
    
    private func shrinkConflictingTasks(for task: TaskOnRing, in allTasks: [TaskOnRing]) -> [TaskOnRing] {
        // Реализация сжатия конфликтующих задач
        return []
    }
    
    private func findAlternativeSlot(for task: TaskOnRing, in allTasks: [TaskOnRing]) -> [TaskOnRing] {
        // Реализация поиска альтернативного слота
        return []
    }
    
    private func splitConflictingTasks(for task: TaskOnRing, in allTasks: [TaskOnRing]) -> [TaskOnRing] {
        // Реализация разделения конфликтующих задач
        return []
    }
}

// MARK: - Additional Notification Names
extension Notification.Name {
    static let taskManagementSelectedDateChanged = Notification.Name("TaskManagementSelectedDateChanged")
    static let taskManagementErrorOccurred = Notification.Name("TaskManagementErrorOccurred")
}
