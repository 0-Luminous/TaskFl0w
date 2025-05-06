//
//  WeekCalendarView.swift
//  TaskFl0w
//
//  Created by Yan on 3/5/25.
//

import SwiftUI

// Компонент для отображения недельного календаря
struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    private let calendar = Calendar.current
    @State private var weekStartDate = Date()
    @State private var currentWeekIndex = 0
    @State private var weekCalendarOffset: CGFloat = 0
    @State private var visibleMonth: Date
    @State private var showMonthCalendar = false
    @State private var showMonthYearPicker = false
    
    // Добавляем ссылку на общее состояние календаря
    @ObservedObject private var calendarState = CalendarState.shared
    
    var onHideCalendar: (() -> Void)?
    var disableMonthExpansion: Bool = false
    
    init(selectedDate: Binding<Date>, disableMonthExpansion: Bool = false, initialShowMonthCalendar: Bool = false, onHideCalendar: (() -> Void)? = nil) {
        self._selectedDate = selectedDate
        self.onHideCalendar = onHideCalendar
        self.disableMonthExpansion = disableMonthExpansion
        self._showMonthCalendar = State(initialValue: initialShowMonthCalendar)
        self._visibleMonth = State(initialValue: selectedDate.wrappedValue)
    }
    
    var body: some View {
        ZStack {
            // Отображаем MonthCalendarView, если showMonthCalendar = true
            if showMonthCalendar {
                MonthCalendarView(
                    selectedDate: $selectedDate,
                    onHideCalendar: {
                        // При скрытии месячного календаря, вызываем onHideCalendar
                        onHideCalendar?()
                    }
                )
                .transition(.move(edge: .top))
            } else {
                // Недельный календарь
                VStack(spacing: 10) {
                    // Заменяем MonthYearHeader на MonthYearHeaderButton
                    MonthYearHeaderButton(
                        date: visibleMonth,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                showMonthYearPicker.toggle()
                            }
                        }
                    )
                    
                    if showMonthYearPicker {
                        // Компонент для выбора месяца и года
                        MonthYearPickerView(
                            selectedDate: $visibleMonth,
                            onDateSelected: { newDate in
                                // Прокручиваем к выбранному месяцу
                                let components = calendar.dateComponents([.day], from: selectedDate)
                                var newComponents = calendar.dateComponents([.year, .month], from: newDate)
                                newComponents.day = components.day
                                
                                if let date = calendar.date(from: newComponents) {
                                    selectedDate = date
                                    updateWeekStartDate()
                                }
                                
                                withAnimation(.spring(response: 0.3)) {
                                    showMonthYearPicker = false
                                }
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        // Секция с календарем - показываем только если не открыт выбор месяца и года
                        CalendarSection
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal, 10)
                .offset(y: weekCalendarOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Если свайп вверх - скрываем календарь
                            if value.translation.height < 0 {
                                weekCalendarOffset = value.translation.height
                            } 
                            // Если свайп вниз - показываем месячный календарь (только если не отключено)
                            else if value.translation.height > 0 && !disableMonthExpansion {
                                weekCalendarOffset = value.translation.height / 3
                            }
                        }
                        .onEnded { value in
                            // Скрываем календарь при свайпе вверх
                            if value.translation.height < -20 {
                                hideCalendar()
                            } 
                            // Показываем месячный календарь при свайпе вниз (только если не отключено)
                            else if value.translation.height > 50 && !disableMonthExpansion {
                                DispatchQueue.main.async {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        showMonthCalendar = true
                                    }
                                }
                            } 
                            // Возвращаем в исходное положение
                            else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    weekCalendarOffset = 0
                                }
                            }
                        }
                )
                .onChange(of: selectedDate) { _, newValue in
                    // Обновляем visibleMonth при изменении selectedDate
                    visibleMonth = newValue
                }
            }
        }
        .onAppear {
            // Используем метод вместо прямого присваивания
            calendarState.setWeekCalendarVisible(true)
        }
        .onDisappear {
            calendarState.setWeekCalendarVisible(false)
        }
    }
    
    // Секция календаря вынесена в отдельное свойство
    private var CalendarSection: some View {
        // Прокручиваемые ячейки с днями недели
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                // Добавляем отступы внутри контента ScrollView, а не снаружи
                LazyHStack(spacing: 8) { // Уменьшаем отступы между неделями
                    ForEach(-52...52, id: \.self) { weekIndex in
                        HStack(spacing: 8) { // Уменьшаем отступы между днями
                            ForEach(0..<7, id: \.self) { dayIndex in
                                let date = getDateForIndex(weekIndex: weekIndex, dayIndex: dayIndex)
                                
                                DayCell(
                                    date: date,
                                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                    dayName: dayNames[dayIndex]
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedDate = date
                                    }
                                }
                                // Используем саму дату как идентификатор ячейки
                                .id("\(calendar.component(.year, from: date))-\(calendar.component(.month, from: date))-\(calendar.component(.day, from: date))")
                                // Обновляем visibleMonth, когда элемент становится видимым
                                .onAppear {
                                    // Обновляем только если месяц отличается от текущего visibleMonth
                                    if !calendar.isDate(date, equalTo: visibleMonth, toGranularity: .month) {
                                        // Обновляем только если это первый день недели
                                        if dayIndex == 0 {
                                            visibleMonth = date
                                        }
                                    }
                                }
                            }
                        }
                        .id(weekIndex)
                    }
                }
                .padding(.horizontal, 2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 65)
            .clipShape(Rectangle())
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            // Добавляем модификатор декларативной пагинации
            .scrollTargetBehavior(.viewAligned)
            .scrollTargetLayout()
            .onAppear {
                updateWeekStartDate()
                // Вычисляем индекс недели для selectedDate относительно текущей недели
                let weekIdx = getWeekIndex(for: selectedDate)
                // Прокручиваем к неделе с выбранной датой без анимации и задержки
                scrollProxy.scrollTo(weekIdx, anchor: .center)
            }
        }
        .padding(0)
    }
    
    // Получаем индекс недели для даты относительно текущей недели
    private func getWeekIndex(for date: Date) -> Int {
        let startOfBaseWeek = calendar.startOfDay(for: weekStartDate)
        let startOfTargetWeek = getStartOfWeek(for: date)
        
        let components = calendar.dateComponents([.weekOfYear], from: startOfBaseWeek, to: startOfTargetWeek)
        return components.weekOfYear ?? 0
    }
    
    // Получаем начало недели для даты
    private func getStartOfWeek(for date: Date) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Понедельник
        
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }
    
    private func getDateForIndex(weekIndex: Int, dayIndex: Int) -> Date {
        let weekOffset = calendar.date(byAdding: .weekOfYear, value: weekIndex, to: weekStartDate) ?? weekStartDate
        return calendar.date(byAdding: .day, value: dayIndex, to: weekOffset) ?? weekStartDate
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }
    
    private var dayNames: [String] {
        ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    }
    
    private func updateWeekStartDate() {
        // Находим начало недели для выбранной даты
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Начало с понедельника для русской локали
        
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)
        weekStartDate = calendar.date(from: components) ?? Date()
    }
    
    // Функция для скрытия календаря, добавленная из ClockViewIOS
    private func hideCalendar() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            weekCalendarOffset = -200
        }
        
        // Вызываем после завершения анимации
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            calendarState.setWeekCalendarVisible(false)
            onHideCalendar?()
        }
    }
}

// Компонент для отображения ячейки дня
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let dayName: String
    
    var body: some View {
        VStack(spacing: 2) {
            // День недели
            Text(dayName)
                .font(.caption2)
                .foregroundColor(textColor)
            
            // Число
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textColor)
        }
        .frame(width: 40, height: 60)
        .background(isSelected ? Color.blue : Color(red: 0.098, green: 0.098, blue: 0.098))
        .cornerRadius(20)
        .shadow(color: isSelected ? Color.blue.opacity(0.5) : Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isToday && !isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
    
    // Проверяем, является ли дата сегодняшней
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    // Определяем цвет текста в зависимости от дня недели
    private var textColor: Color {
        // Выбранная ячейка имеет черный текст (для контраста с синим фоном)
        if isSelected {
            return .black
        }
        
        // Проверяем, является ли день выходным
        let weekday = Calendar.current.component(.weekday, from: date)
        // В Calendar.current, 1 - воскресенье, 7 - суббота
        let isWeekend = weekday == 1 || weekday == 7
        
        if isWeekend {
            return .red
        } else {
            // Для будних дней используем белый цвет для названий дней и чисел
            return .white
        }
    }
}

