//
//  TimeManagementViewModel.swift
//  TaskFl0w
//
//  Created by Yan on 16/06/24.
//

import SwiftUI
import Foundation
import Combine

/// ViewModel для управления временем и временными вычислениями
@MainActor
final class TimeManagementViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentDate = Date()
    @Published var selectedDate = Date()
    @Published var zeroPosition: Double = 0 {
        didSet { saveZeroPosition() }
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(initialDate: Date = Date()) {
        self.selectedDate = initialDate
        self.currentDate = initialDate
        self.zeroPosition = UserDefaults.standard.double(forKey: "zeroPosition")
        
        setupNotifications()
    }
    
    // MARK: - Public Methods
    
    /// Обновляет текущее время только если выбранная дата - сегодня
    func updateCurrentTimeIfNeeded() {
        guard Calendar.current.isDate(selectedDate, inSameDayAs: Date()) else { return }
        currentDate = Date()
    }
    
    /// Получает время с учетом смещения нулевой позиции
    func getTimeWithZeroOffset(_ date: Date, inverse: Bool = false) -> Date {
        // Логика будет реализована при интеграции с RingTimeCalculator
        return date
    }
    
    /// Конвертирует угол в время
    func angleToTime(_ angle: Double) -> Date {
        // Логика будет реализована при интеграции с RingTimeCalculator
        return selectedDate
    }
    
    /// Конвертирует время в угол
    func timeToAngle(_ date: Date) -> Double {
        // Логика будет реализована при интеграции с RingTimeCalculator
        return 0.0
    }
    
    /// Обновляет нулевую позицию
    func updateZeroPosition(_ newPosition: Double) {
        zeroPosition = newPosition
    }
    
    /// Проверяет, является ли дата сегодняшним днем
    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    /// Получает начало дня для указанной даты
    func startOfDay(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    /// Получает конец дня для указанной даты
    func endOfDay(for date: Date) -> Date {
        let startOfNextDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay(for: date))!
        return Calendar.current.date(byAdding: .second, value: -1, to: startOfNextDay)!
    }
    
    // MARK: - Private Methods
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleZeroPositionChange),
            name: .zeroPositionDidChange,
            object: nil
        )
    }
    
    @objc private func handleZeroPositionChange() {
        // Обновление будет происходить через UserDefaults или напрямую
        objectWillChange.send()
    }
    
    private func saveZeroPosition() {
        UserDefaults.standard.set(zeroPosition, forKey: "zeroPosition")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - TimeManagementProtocol

protocol TimeManagementProtocol: ObservableObject {
    var currentDate: Date { get }
    var selectedDate: Date { get set }
    var zeroPosition: Double { get set }
    
    func updateCurrentTimeIfNeeded()
    func getTimeWithZeroOffset(_ date: Date, inverse: Bool) -> Date
    func angleToTime(_ angle: Double) -> Date
    func timeToAngle(_ date: Date) -> Double
    func updateZeroPosition(_ newPosition: Double)
}

extension TimeManagementViewModel: TimeManagementProtocol {} 