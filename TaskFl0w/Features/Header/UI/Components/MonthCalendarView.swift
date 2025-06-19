//
//  MonthCalendarView.swift
//  TaskFl0w
//
//  Created by Yan on 6/5/25.
//

import SwiftUI
import UIKit

// Компонент для отображения месячного календаря
struct MonthCalendarView: View {

    @Binding var selectedDate: Date

    let deadlineDate: Date?
    let isSwipeToHideEnabled: Bool

    private let calendar = Calendar.current

    @State private var monthStartDate = Date()
    @State private var currentMonthIndex = 0
    @State private var monthCalendarOffset: CGFloat = 0
    @State private var visibleMonth: Date
    @State private var showMonthYearPicker = false
    @State private var opacity: Double = 1.0
    
    @ObservedObject private var calendarState = CalendarState.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var onHideCalendar: (() -> Void)?
    
    init(selectedDate: Binding<Date>, deadlineDate: Date? = nil, onHideCalendar: (() -> Void)? = nil, isSwipeToHideEnabled: Bool = true) {
        self._selectedDate = selectedDate
        self.deadlineDate = deadlineDate
        self.onHideCalendar = onHideCalendar
        self._visibleMonth = State(initialValue: selectedDate.wrappedValue)
        self.isSwipeToHideEnabled = isSwipeToHideEnabled
    }
    
    var body: some View {
        VStack(spacing: 8) {
            MonthYearHeaderButton(
                date: visibleMonth,
                onTap: {
                    withAnimation(.spring(response: 0.3)) {
                        showMonthYearPicker.toggle()
                    }
                }
            )
            
            if showMonthYearPicker {
                MonthYearPickerView(
                    selectedDate: $visibleMonth,
                    onDateSelected: { newDate in
                        let components = calendar.dateComponents([.day], from: selectedDate)
                        var newComponents = calendar.dateComponents([.year, .month], from: newDate)
                        newComponents.day = components.day
                        
                        if let date = calendar.date(from: newComponents) {
                            selectedDate = date
                        }
                        
                        withAnimation(.spring(response: 0.3)) {
                            showMonthYearPicker = false
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
            } else {
                CalendarSection
                    .cornerRadius(16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(themeManager.isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 0.9, green: 0.9, blue: 0.9))
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 10)
        .offset(y: monthCalendarOffset)
        .opacity(opacity)
        .gesture(
            isSwipeToHideEnabled ? 
            AnyGesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height < 0 {
                            monthCalendarOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        let halfwayPoint: CGFloat = -100 // Примерная половина высоты календаря
                        
                        if value.translation.height < -20 || (value.translation.height < 0 && value.predictedEndTranslation.height < halfwayPoint) {
                            hideCalendar()
                        } else {
                            // Возвращаем в исходное положение
                            withAnimation(.easeInOut(duration: 0.3)) {
                                monthCalendarOffset = 0
                            }
                        }
                    }
            ) : nil
        )
        .onChange(of: selectedDate) { _, newValue in
            visibleMonth = newValue
        }
        .onAppear {
            calendarState.setMonthCalendarVisible(true)
        }
        .onDisappear {
            calendarState.setMonthCalendarVisible(false)
        }
    }
    
    private var CalendarSection: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(-24...24, id: \.self) { monthIndex in
                        MonthGrid(
                            monthIndex: monthIndex,
                            baseDate: monthStartDate,
                            deadlineDate: deadlineDate,
                            onDateSelected: { date in
                                withAnimation(.spring(response: 0.3)) {
                                    selectedDate = date
                                }
                            },
                            onVisibleMonthChanged: { date in
                                if !calendar.isDate(date, equalTo: visibleMonth, toGranularity: .month) {
                                    visibleMonth = date
                                }
                            },
                            selectedDate: $selectedDate
                        )
                        .id(monthIndex)
                    }
                }
                .padding(.horizontal, 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 310)
            .clipShape(Rectangle())
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            .scrollTargetBehavior(.viewAligned)
            .scrollTargetLayout()
            .onAppear {
                updateMonthStartDate()
                let monthIdx = getMonthIndex(for: selectedDate)
                scrollProxy.scrollTo(monthIdx, anchor: .center)
            }
        }
        .padding(0)
    }
    
    private func updateMonthStartDate() {
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        monthStartDate = calendar.date(from: components) ?? Date()
    }
    
    private func getMonthIndex(for date: Date) -> Int {
        let startOfBaseMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthStartDate))!
        let startOfTargetMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        
        let components = calendar.dateComponents([.month, .year], from: startOfBaseMonth, to: startOfTargetMonth)
        return components.year! * 12 + components.month!
    }
    
    private var dayNames: [String] {
        ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    }
    
    private func hideCalendar() {
        // Комбинируем смещение и уменьшение прозрачности
        withAnimation(.easeInOut(duration: 0.3)) {
            monthCalendarOffset = -150 // Меньшее смещение, так как будет еще прозрачность
            opacity = 0 // Полностью прозрачный
        }
        
        // Вызываем после анимации
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Сначала вызываем onHideCalendar
            onHideCalendar?()
            
            // Затем обновляем состояние календаря
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                calendarState.setMonthCalendarVisible(false)
            }
        }
    }
}

// Компонент для отображения сетки месяца
struct MonthGrid: View {
    let monthIndex: Int
    let baseDate: Date
    let deadlineDate: Date?
    let onDateSelected: (Date) -> Void
    let onVisibleMonthChanged: (Date) -> Void
    let hapticsManager = HapticsManager.shared

    @ObservedObject private var themeManager = ThemeManager.shared
    @Binding var selectedDate: Date

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 7)
    
    var body: some View {
        let monthDate = getMonthForIndex(monthIndex: monthIndex)
        let daysInMonth = getDaysInMonth(monthDate)
        
        VStack(spacing: 8) {
            // Дни недели
            HStack(spacing: 12) {
                ForEach(0..<7, id: \.self) { index in
                    Text(dayNames[index])
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                        .frame(width: 36, height: 20)
                }
            }
            
            // Сетка дней
            LazyVGrid(columns: columns, spacing: 8) {
                // Используем индекс вместо самого объекта для уникальной идентификации
                ForEach(0..<daysInMonth.count, id: \.self) { index in
                    let day = daysInMonth[index]
                    if day.belongsToMonth {
                        // Модифицируем ячейку, чтобы показать даты до deadline
                        ZStack {
                            // Основной фон ячейки
                            Circle()
                                .fill(backgroundColorForDate(day.date))
                                .frame(width: 36, height: 36)
                                .shadow(color: shadowColorForDate(day.date), radius: 2, x: 0, y: 1)
                            
                            // Специальный градиентный фон для выбранной даты в режиме deadline
                            if calendar.isDate(day.date, inSameDayAs: selectedDate) && deadlineDate != nil {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.red.opacity(0.8),
                                                Color.orange.opacity(0.6)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 36, height: 36)
                                    .shadow(color: Color.red.opacity(0.4), radius: 4, x: 0, y: 2)
                            }
                            
                            // Дополнительный круг для сегодняшнего дня
                            if Calendar.current.isDateInToday(day.date) && !calendar.isDate(day.date, inSameDayAs: selectedDate) {
                                Circle()
                                    .stroke(Color.blue, lineWidth: 1.5)
                                    .frame(width: 36, height: 36)
                            }
                            
                            // Дополнительная визуализация для deadline
                            if let deadline = deadlineDate, calendar.isDate(day.date, inSameDayAs: deadline) && !calendar.isDate(day.date, inSameDayAs: selectedDate) {
                                Circle()
                                    .stroke(Color.red, lineWidth: 2)
                                    .frame(width: 38, height: 38)
                            }
                            
                            // Число
                            Text("\(Calendar.current.component(.day, from: day.date))")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(textColorForDate(day.date, isSelected: calendar.isDate(day.date, inSameDayAs: selectedDate)))
                        }
                        .frame(width: 38, height: 38)
                        .onTapGesture {
                            // Проверяем, можно ли выбрать дату
                            if canSelectDate(day.date) {
                                hapticsManager.triggerMediumFeedback()
                                onDateSelected(day.date)
                            } else {
                                hapticsManager.triggerLightFeedback()
                            }
                        }
                    } else {
                        // Пустая ячейка для дней не из текущего месяца
                        Color.clear
                            .frame(width: 38, height: 38)
                    }
                }
            }
        }
        .frame(width: 330)
        .onAppear {
            onVisibleMonthChanged(monthDate)
        }
    }
    
    private func getMonthForIndex(monthIndex: Int) -> Date {
        return calendar.date(byAdding: .month, value: monthIndex, to: baseDate) ?? baseDate
    }
    
    private func getDaysInMonth(_ date: Date) -> [MonthDay] {
        let range = calendar.range(of: .day, in: .month, for: date)!
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        
        // Получаем день недели для первого дня месяца (1 = понедельник, 7 = воскресенье)
        var firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        // Преобразуем к нашей системе (0 = понедельник)
        firstWeekday = (firstWeekday + 5) % 7
        
        var days = [MonthDay]()
        
        // Добавляем пустые ячейки для выравнивания с уникальными датами
        for i in 0..<firstWeekday {
            // Создаем уникальную дату для каждой пустой ячейки
            let uniqueDate = calendar.date(byAdding: .day, value: -i - 1, to: firstDayOfMonth)!
            days.append(MonthDay(date: uniqueDate, belongsToMonth: false))
        }
        
        // Добавляем дни текущего месяца
        for day in 1...range.count {
            let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth)!
            days.append(MonthDay(date: date, belongsToMonth: true))
        }
        
        // Добавляем пустые ячейки в конце до 42 (6 недель) с уникальными датами
        let daysAdded = days.count
        for i in 0..<(42 - daysAdded) {
            // Создаем уникальную дату для каждой пустой ячейки
            let lastDay = calendar.date(byAdding: .day, value: range.count - 1, to: firstDayOfMonth)!
            let uniqueDate = calendar.date(byAdding: .day, value: i + 1, to: lastDay)!
            days.append(MonthDay(date: uniqueDate, belongsToMonth: false))
        }
        
        return days
    }
    
    private var dayNames: [String] {
        [
            NSLocalizedString("week.monday", comment: ""),
            NSLocalizedString("week.tuesday", comment: ""),
            NSLocalizedString("week.wednesday", comment: ""),
            NSLocalizedString("week.thursday", comment: ""),
            NSLocalizedString("week.friday", comment: ""),
            NSLocalizedString("week.saturday", comment: ""),
            NSLocalizedString("week.sunday", comment: ""),
        ]
    }
    
    private func backgroundColorForDate(_ date: Date) -> Color {
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        let startOfDate = calendar.startOfDay(for: date)
        
        // Прошедшие даты - полупрозрачный фон
        if startOfDate < startOfToday {
            return (themeManager.isDarkMode 
                ? Color(red: 0.098, green: 0.098, blue: 0.098) 
                : Color(red: 0.9, green: 0.9, blue: 0.9)).opacity(0.3)
        }
        
        // Выбранная дата - используем разные цвета в зависимости от контекста
        if calendar.isDate(date, inSameDayAs: selectedDate) {
            // Если это календарь для deadline (deadlineDate передан), используем красно-оранжевый градиент
            if deadlineDate != nil {
                return Color.clear // Возвращаем прозрачный, так как градиент будет в ZStack
            } else {
                return Color.blue // Обычный синий для других календарей
            }
        }
        
        // Даты в диапазоне от сегодня до deadline
        if let deadline = deadlineDate {
            let startOfDeadline = calendar.startOfDay(for: deadline)
            
            // Проверяем, находится ли дата в диапазоне от сегодня до deadline (включительно)
            if startOfDate >= startOfToday && startOfDate <= startOfDeadline {
                return themeManager.isDarkMode 
                    ? Color.red.opacity(0.3) 
                    : Color.red.opacity(0.2)
            }
        }
        
        // Обычный фон
        return themeManager.isDarkMode 
            ? Color(red: 0.098, green: 0.098, blue: 0.098) 
            : Color(red: 0.9, green: 0.9, blue: 0.9)
    }
    
    private func shadowColorForDate(_ date: Date) -> Color {
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        let startOfDate = calendar.startOfDay(for: date)
        
        // Прошедшие даты - полупрозрачная тень
        if startOfDate < startOfToday {
            return Color.black.opacity(0.1)
        }
        
        if calendar.isDate(date, inSameDayAs: selectedDate) {
            return deadlineDate != nil ? Color.red.opacity(0.5) : Color.blue.opacity(0.5)
        }
        
        // Тень для дат в диапазоне от сегодня до deadline
        if let deadline = deadlineDate {
            let startOfDeadline = calendar.startOfDay(for: deadline)
            
            if startOfDate >= startOfToday && startOfDate <= startOfDeadline {
                return Color.red.opacity(0.3)
            }
        }
        
        return Color.black.opacity(0.2)
    }
    
    private func textColorForDate(_ date: Date, isSelected: Bool) -> Color {
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        let startOfDate = calendar.startOfDay(for: date)
        
        // Прошедшие даты - полупрозрачный текст
        if startOfDate < startOfToday {
            let baseColor = themeManager.isDarkMode ? Color.white : Color.black
            return baseColor.opacity(0.3)
        }
        
        // Выбранная ячейка имеет белый текст (для контраста с синим фоном)
        if isSelected {
            return .white
        }
        
        // Для дат в диапазоне от сегодня до deadline используем белый текст для лучшего контраста
        if let deadline = deadlineDate {
            let startOfDeadline = calendar.startOfDay(for: deadline)
            
            if startOfDate >= startOfToday && startOfDate <= startOfDeadline {
                return .white
            }
        }
        
        // Проверяем, является ли день выходным
        let weekday = Calendar.current.component(.weekday, from: date)
        // В Calendar.current, 1 - воскресенье, 7 - суббота
        let isWeekend = weekday == 1 || weekday == 7
        
        if isWeekend {
            return .red
        } else {
            // Для будних дней используем белый цвет
            return themeManager.isDarkMode ? .white : .black
        }
    }
    
    private func canSelectDate(_ date: Date) -> Bool {
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        let startOfDate = calendar.startOfDay(for: date)
        
        // Нельзя выбирать прошедшие даты
        return startOfDate >= startOfToday
    }
}

// Структура для представления дня в месяце
struct MonthDay: Hashable {
    let date: Date
    let belongsToMonth: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(belongsToMonth)
    }
    
    static func == (lhs: MonthDay, rhs: MonthDay) -> Bool {
        return lhs.date == rhs.date && lhs.belongsToMonth == rhs.belongsToMonth
    }
}
