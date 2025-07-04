//
//  TimeManagementViewModel.swift
//  TaskFl0w
//
//  Created by Yan on 16/06/24.
//

import SwiftUI
import Foundation
import Combine

/// ✅ ОПТИМИЗИРОВАННЫЙ ViewModel для управления временем и временными вычислениями
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
    
    // ✅ ОПТИМИЗАЦИЯ: Кэшируем календарь для переиспользования
    private let calendar = Calendar.current
    
    // ✅ ОПТИМИЗАЦИЯ: Отслеживаем последнее обновление
    private var lastUpdateTime = Date.distantPast
    
    // MARK: - Initialization
    
    init(initialDate: Date = Date()) {
        self.selectedDate = initialDate
        self.currentDate = initialDate
        self.zeroPosition = UserDefaults.standard.double(forKey: "zeroPosition")
        
        setupNotifications()
    }
    
    // MARK: - Public Methods
    
    /// ✅ КРИТИЧЕСКАЯ ОПТИМИЗАЦИЯ: updateCurrentTimeIfNeeded 
    func updateCurrentTimeIfNeeded() {
        // Проверяем только если выбранная дата - сегодня
        guard calendar.isDate(selectedDate, inSameDayAs: Date()) else { return }
        
        let now = Date()
        
        // ✅ ОПТИМИЗАЦИЯ: Обновляем только если прошла минута
        guard !calendar.isDate(lastUpdateTime, equalTo: now, toGranularity: .minute) else { return }
        
        currentDate = now
        lastUpdateTime = now
    }
    
    /// Получает время с учетом смещения нулевой позиции
    func getTimeWithZeroOffset(_ date: Date, inverse: Bool = false) -> Date {
        // Используем кэшированный календарь
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)

        // Получаем часы и минуты
        let totalMinutes = Double(components.hour! * 60 + components.minute!)

        // Вычисляем смещение в минутах
        let offsetDegrees = inverse ? -zeroPosition : zeroPosition
        let offsetHours = offsetDegrees / 15.0  // 360 / 24 = 15
        let offsetMinutes = offsetHours * 60

        // Применяем смещение с учетом 24-часового цикла
        let adjustedMinutes = (totalMinutes - offsetMinutes + 1440).truncatingRemainder(dividingBy: 1440)

        // Конвертируем обратно в часы и минуты
        components.hour = Int(adjustedMinutes / 60)
        components.minute = Int(adjustedMinutes.truncatingRemainder(dividingBy: 60))

        return calendar.date(from: components) ?? date
    }
    
    /// Конвертирует угол в время
    func angleToTime(_ angle: Double) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)

        // Преобразуем угол в минуты
        var totalMinutes = angle * 4.0 // 1440 / 360 = 4

        // Учитываем zeroPosition и переводим в 24-часовой формат
        totalMinutes = (totalMinutes + (270 - zeroPosition) * 4.0 + 1440).truncatingRemainder(dividingBy: 1440)

        components.hour = Int(totalMinutes / 60)
        components.minute = Int(totalMinutes.truncatingRemainder(dividingBy: 60))

        return calendar.date(from: components) ?? selectedDate
    }
    
    /// Конвертирует время в угол
    func timeToAngle(_ date: Date) -> Double {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let totalMinutes = Double(components.hour! * 60 + components.minute!)
        
        var angle = totalMinutes / 4.0 // 1440 / 360 = 4
        let zeroOffset = 270.0 - zeroPosition
        
        angle = (angle - zeroOffset + 360.0).truncatingRemainder(dividingBy: 360.0)
        return angle
    }
    
    /// Обновляет нулевую позицию
    func updateZeroPosition(_ newPosition: Double) {
        zeroPosition = newPosition
    }
    
    /// Проверяет, является ли дата сегодняшним днем
    func isToday(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: Date())
    }
    
    /// Получает начало дня для указанной даты
    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    /// Получает конец дня для указанной даты
    func endOfDay(for date: Date) -> Date {
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay(for: date))!
        return calendar.date(byAdding: .second, value: -1, to: startOfNextDay)!
    }
    
    // MARK: - Private Methods
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleZeroPositionChange),
            name: NSNotification.Name("ZeroPositionDidChange"),
            object: nil
        )
    }
    
    @objc private func handleZeroPositionChange() {
        // ✅ ОПТИМИЗАЦИЯ: Убираем избыточный objectWillChange.send()
        // @Published свойство zeroPosition уже уведомляет об изменениях
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