//
//  DemoClockViewModel.swift
//  TaskFl0w
//
//  Created by Yan on 7/6/25.
//

import SwiftUI
import Foundation

// Создаем специальный изолированный ViewModel для демонстрации
class DemoClockViewModel: ObservableObject {
    @Published var tasks: [TaskOnRing] = []
    
    // Изменяем с private на internal для доступа из DemoTaskManagement
    internal var demoTasks: [TaskOnRing] = []
    
    // Добавляем необходимые свойства для совместимости с компонентами
    var zeroPosition: Double = 0.0
    var taskArcLineWidth: CGFloat = 20.0
    var outerRingLineWidth: CGFloat = 20.0
    var isAnalogArcStyle: Bool = false
    var showTimeOnlyForActiveTask: Bool = false
    
    // Изолированное управление задачами только для демонстрации - ДЕЛАЕМ OPTIONAL
    lazy var taskManagement: DemoTaskManagement? = {
        return DemoTaskManagement(viewModel: self)
    }()
    
    func clearAllTasks() {
        demoTasks.removeAll()
        tasks.removeAll()
    }
    
    // Добавляем методы для управления задачами напрямую из ViewModel
    func addDemoTask(_ task: TaskOnRing) {
        demoTasks.append(task)
        tasks = demoTasks
    }
    
    func removeDemoTasks(_ tasksToRemove: [TaskOnRing]) {
        for task in tasksToRemove {
            demoTasks.removeAll { $0.id == task.id }
        }
        tasks = demoTasks
    }
    
    static func empty() -> DemoClockViewModel {
        let vm = DemoClockViewModel()
        vm.tasks = []
        return vm
    }
    
    deinit {
        // Принудительно очищаем все данные при освобождении памяти
        clearAllTasks()
        demoTasks.removeAll()
        tasks.removeAll()
        taskManagement = nil  // Теперь это работает, так как taskManagement optional
        print("DemoClockViewModel успешно освобожден из памяти")
    }
}

// Создаем изолированный TaskManagement для демо
class DemoTaskManagement {
    private weak var viewModel: DemoClockViewModel?
    
    init(viewModel: DemoClockViewModel) {
        self.viewModel = viewModel
    }
    
    func addTask(_ task: TaskOnRing) {
        viewModel?.addDemoTask(task)
    }
    
    func removeMultipleTasks(_ tasks: [TaskOnRing]) async throws {
        await MainActor.run {
            viewModel?.removeDemoTasks(tasks)
        }
    }
    
    deinit {
        viewModel = nil
        print("DemoTaskManagement освобожден")
    }
}

