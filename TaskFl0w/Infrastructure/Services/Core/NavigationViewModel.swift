//
//  NavigationViewModel.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation
import SwiftUI

/// Типобезопасные маршруты навигации
enum Route: Hashable {
    case clock
    case taskList(category: TaskCategoryModel?)
    case taskDetail(taskId: UUID)
    case settings
    case categoryEditor
    case calendar
    case taskTimeline
}

/// ViewModel для управления навигацией
@MainActor
final class NavigationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var navigationStack: [Route] = []
    @Published var currentRoute: Route = .clock
    
    // MARK: - Navigation Methods
    
    /// Переходит к указанному маршруту
    func navigate(to route: Route) {
        currentRoute = route
    }
    
    /// Добавляет маршрут в стек навигации
    func push(_ route: Route) {
        navigationStack.append(route)
        currentRoute = route
    }
    
    /// Возвращается на предыдущий экран
    func pop() {
        guard !navigationStack.isEmpty else { return }
        
        _ = navigationStack.popLast()
        currentRoute = navigationStack.last ?? .clock
    }
    
    /// Возвращается к корневому экрану
    func popToRoot() {
        navigationStack.removeAll()
        currentRoute = .clock
    }
    
    /// Заменяет текущий маршрут
    func replace(with route: Route) {
        if !navigationStack.isEmpty {
            navigationStack.removeLast()
        }
        push(route)
    }
    
    /// Проверяет, является ли указанный маршрут текущим
    func isCurrentRoute(_ route: Route) -> Bool {
        currentRoute == route
    }
    
    /// Получает глубину стека навигации
    var navigationDepth: Int {
        navigationStack.count
    }
    
    /// Проверяет, находимся ли мы на корневом экране
    var isAtRoot: Bool {
        navigationStack.isEmpty
    }
} 