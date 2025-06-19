//
//  CalendarState.swift
//  TaskFl0w
//
//  Created by Yan on 6/5/25.
//

import SwiftUI

// Класс для управления состоянием календаря
class CalendarState: ObservableObject {
    // Публикуемые свойства для отслеживания видимости календарей
    @Published var isWeekCalendarVisible: Bool = false
    @Published var isMonthCalendarVisible: Bool = false
    
    // Синглтон для доступа из любого места приложения
    static let shared = CalendarState()
    
    // Добавляем переменную-флаг для предотвращения частых изменений
    private var isChangingState = false
    
    private init() {}
    
    // Добавляем методы для безопасного обновления состояния
    func setWeekCalendarVisible(_ visible: Bool) {
        // Проверяем, не происходит ли уже изменение состояния
        if isChangingState {
            return
        }
        
        isChangingState = true
        
        DispatchQueue.main.async {
            if visible {
                self.isMonthCalendarVisible = false
                self.isWeekCalendarVisible = true
            } else {
                self.isWeekCalendarVisible = false
            }
            
            // Освобождаем блокировку через короткий промежуток времени
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isChangingState = false
            }
        }
    }
    
    func setMonthCalendarVisible(_ visible: Bool) {
        // Проверяем, не происходит ли уже изменение состояния
        if isChangingState {
            return
        }
        
        isChangingState = true
        
        DispatchQueue.main.async {
            if visible {
                self.isWeekCalendarVisible = false
            }
            self.isMonthCalendarVisible = visible
            
            // Освобождаем блокировку через короткий промежуток времени
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isChangingState = false
            }
        }
    }
}

