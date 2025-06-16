import Combine
import CoreData
import Foundation
import OSLog

// MARK: - Улучшенный StateService (замена Singleton)
@MainActor
final class SharedStateService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var tasks: [TaskOnRing] = [] {
        didSet {
            notifyTasksUpdated()
        }
    }
    
    @Published var selectedDate = Date()
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    // MARK: - Properties
    let context: NSManagedObjectContext
    private let logger = Logger(subsystem: "TaskFl0w", category: "SharedStateService")
    private var tasksUpdateCallbacks: [() -> Void] = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization (убираем Singleton)
    init(context: NSManagedObjectContext) {
        self.context = context
        setupBindings()
        
        // Загружаем начальные данные асинхронно
        Task {
            await fetchInitialData()
        }
    }
    
    // MARK: - Convenience initializer для совместимости
    convenience init() {
        let container = PersistenceController.shared.container
        self.init(context: container.viewContext)
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Автоматическая перезагрузка при изменении даты
        $selectedDate
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] date in
                Task { @MainActor [weak self] in
                    await self?.loadTasks(for: date)
                }
            }
            .store(in: &cancellables)
    }
    
    private func fetchInitialData() async {
        await loadTasks(for: selectedDate)
    }
    
    // MARK: - Task Management
    func loadTasks(for date: Date) async {
        isLoading = true
        error = nil
        
        do {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
            
            let taskRequest = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
            taskRequest.predicate = NSPredicate(
                format: "startTime >= %@ AND startTime < %@",
                startOfDay as NSDate,
                endOfDay as NSDate
            )
            taskRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \TaskEntity.startTime, ascending: true)
            ]
            
            let taskEntities = try context.fetch(taskRequest)
            self.tasks = taskEntities.map { $0.taskModel }
            
            logger.info("Загружено \(self.tasks.count) задач для даты \(date)")
        } catch {
            self.error = error
            logger.error("Ошибка загрузки задач: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func saveContext() throws {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            logger.info("Контекст сохранен успешно")
        } catch {
            logger.error("Ошибка сохранения контекста: \(error.localizedDescription)")
            self.error = error
            throw error
        }
    }
    
    func addTask(_ task: TaskOnRing) async {
        do {
            let entity = TaskEntity.from(task, context: context)
            try saveContext()
            
            // Обновляем локальный массив
            self.tasks.append(task)
            logger.info("Добавлена задача: \(task.id)")
        } catch {
            self.error = error
            logger.error("Ошибка добавления задачи: \(error.localizedDescription)")
        }
    }
    
    func updateTask(_ task: TaskOnRing) async {
        do {
            // Находим и обновляем entity
            let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
            request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
            
            if let entity = try context.fetch(request).first {
                // entity.update(from: task) // Метод будет добавлен позже
                try saveContext()
                
                // Обновляем локальный массив
                if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                    self.tasks[index] = task
                }
                
                logger.info("Обновлена задача: \(task.id)")
            }
        } catch {
            self.error = error
            logger.error("Ошибка обновления задачи: \(error.localizedDescription)")
        }
    }
    
    func deleteTask(with id: UUID) async {
        do {
            let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            if let entity = try context.fetch(request).first {
                context.delete(entity)
                try saveContext()
                
                // Обновляем локальный массив
                self.tasks.removeAll { $0.id == id }
                logger.info("Удалена задача: \(id)")
            }
        } catch {
            self.error = error
            logger.error("Ошибка удаления задачи: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Callbacks
    func subscribeToTasksUpdates(_ callback: @escaping () -> Void) {
        tasksUpdateCallbacks.append(callback)
    }

    private func notifyTasksUpdated() {
        tasksUpdateCallbacks.forEach { $0() }
    }
    
    // MARK: - Error Handling
    func clearError() {
        error = nil
    }
}
