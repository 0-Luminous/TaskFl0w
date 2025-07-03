//
//  CentralTimeManager.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI
import Combine

/// Единый менеджер времени для всего приложения
/// Заменяет множественные таймеры одним оптимизированным
@MainActor
final class CentralTimeManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = CentralTimeManager()
    
    // MARK: - Published Properties
    @Published var currentTime = Date()
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var isActive = true
    
    // ✅ ИСПРАВЛЕНИЕ #1: Используем WeakSet вместо Set<TimeSubscriber>
    private var subscribers: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    
    // MARK: - Optimization
    private var lastSecondUpdate = Date()
    private var lastMinuteUpdate = Date()
    private let calendar = Calendar.current
    
    // MARK: - Initialization
    private init() {
        startTimer()
        setupBackgroundHandling()
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isActive else { return }
            
            let now = Date()
            self.currentTime = now
            
            // ✅ ОПТИМИЗАЦИЯ: Уведомляем подписчиков только при необходимости
            self.notifySubscribers(for: now)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Background Handling
    private func setupBackgroundHandling() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pauseUpdates()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resumeUpdates()
        }
    }
    
    // MARK: - Public Methods
    func pauseUpdates() {
        isActive = false
    }
    
    func resumeUpdates() {
        isActive = true
        currentTime = Date() // Обновляем время при возобновлении
    }
    
    // MARK: - Subscription Management
    // ✅ ИСПРАВЛЕНИЕ #1: Упрощенная система подписок
    func subscribe(_ subscriber: AnyObject & TimeSubscriber) {
        subscribers.add(subscriber)
    }
    
    func unsubscribe(_ subscriber: AnyObject & TimeSubscriber) {
        subscribers.remove(subscriber)
    }
    
    // MARK: - Convenience Publishers
    
    /// Publisher для обновлений каждую секунду
    var secondPublisher: AnyPublisher<Date, Never> {
        $currentTime
            .eraseToAnyPublisher()
    }
    
    /// Publisher для обновлений каждую минуту
    var minutePublisher: AnyPublisher<Date, Never> {
        $currentTime
            .filter { [weak self] date in
                guard let self = self else { return false }
                
                let currentMinute = self.calendar.component(.minute, from: date)
                let lastMinute = self.calendar.component(.minute, from: self.lastMinuteUpdate)
                
                if currentMinute != lastMinute {
                    self.lastMinuteUpdate = date
                    return true
                }
                return false
            }
            .eraseToAnyPublisher()
    }
    
    /// Publisher для обновлений каждый час
    var hourPublisher: AnyPublisher<Date, Never> {
        $currentTime
            .filter { [calendar] date in
                calendar.component(.minute, from: date) == 0 &&
                calendar.component(.second, from: date) < 2 // Небольшое окно для захвата
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    private func notifySubscribers(for date: Date) {
        // Преобразуем NSHashTable в массив для безопасной итерации
        let allSubscribers = subscribers.allObjects.compactMap { $0 as? TimeSubscriber }
        
        // Уведомляем активных подписчиков
        for subscriber in allSubscribers {
            subscriber.timeDidUpdate(date)
        }
    }
    
    // ✅ ИСПРАВЛЕНИЕ #2: Простой deinit без изоляции
    // Поскольку CentralTimeManager - синглтон, deinit практически никогда не вызывается
    // Но если нужно, то очистка произойдет автоматически через NotificationCenter
}

// MARK: - TimeSubscriber Protocol
// ✅ ИСПРАВЛЕНИЕ #3: Упрощаем протокол без Hashable
protocol TimeSubscriber: AnyObject {
    func timeDidUpdate(_ date: Date)
}

// MARK: - Convenience Extensions
extension CentralTimeManager {
    
    /// Создает debounced publisher для оптимизации
    func debouncedPublisher(for interval: TimeInterval) -> AnyPublisher<Date, Never> {
        $currentTime
            .debounce(for: .milliseconds(Int(interval * 1000)), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    /// Проверяет, нужно ли обновление UI на основе изменений времени
    func shouldUpdateUI(for component: Calendar.Component) -> Bool {
        let current = calendar.component(component, from: currentTime)
        let previous = calendar.component(component, from: lastSecondUpdate)
        return current != previous
    }
    
    /// Принудительная очистка ресурсов (для тестирования или особых случаев)
    func cleanup() {
        stopTimer()
        subscribers.removeAllObjects()
        NotificationCenter.default.removeObserver(self)
    }
}
