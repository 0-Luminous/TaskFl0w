import Combine
import CoreData
import Foundation

// Синглтон для хранения общего состояния
class SharedStateService: ObservableObject {
    static let shared = SharedStateService()

    let context: NSManagedObjectContext

    @Published var tasks: [TaskOnRing] = [] {
        didSet {
            // Уведомляем подписчиков об изменении
            notifyTasksUpdated()
        }
    }

    private var tasksUpdateCallbacks: [() -> Void] = []
    private var cancellables = Set<AnyCancellable>()

    private init() {
        let container = PersistenceController.shared.container
        self.context = container.viewContext

        // Загружаем начальные данные
        fetchInitialData()
    }

    private func fetchInitialData() {
        let taskRequest = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        do {
            let taskEntities = try context.fetch(taskRequest)
            tasks = taskEntities.map { $0.taskModel }
        } catch {
            print("Ошибка загрузки начальных данных: \(error)")
        }
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
