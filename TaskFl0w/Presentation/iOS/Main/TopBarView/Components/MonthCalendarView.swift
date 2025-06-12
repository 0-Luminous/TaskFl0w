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
    private let calendar = Calendar.current
    @State private var monthStartDate = Date()
    @State private var currentMonthIndex = 0
    @State private var monthCalendarOffset: CGFloat = 0
    @State private var visibleMonth: Date
    
    // Добавляем состояние для отображения выбора месяца/года
    @State private var showMonthYearPicker = false
    
    // Добавляем ссылку на общее состояние календаря
    @ObservedObject private var calendarState = CalendarState.shared

    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Добавлена функция обратного вызова для сокрытия календаря
    var onHideCalendar: (() -> Void)?
    
    // Добавьте переменную состояния для управления прозрачностью
    @State private var opacity: Double = 1.0
    
    // Добавляем параметр для отключения свайпа
    let isSwipeToHideEnabled: Bool
    
    // Инициализатор для установки начального значения visibleMonth
    init(selectedDate: Binding<Date>, onHideCalendar: (() -> Void)? = nil, isSwipeToHideEnabled: Bool = true) {
        self._selectedDate = selectedDate
        self.onHideCalendar = onHideCalendar
        self._visibleMonth = State(initialValue: selectedDate.wrappedValue)
        self.isSwipeToHideEnabled = isSwipeToHideEnabled
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Заголовок с текущим месяцем и годом как кнопка
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
                .fill(themeManager.isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 0.9, green: 0.9, blue: 0.9))
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 10)
        .offset(y: monthCalendarOffset)
        .opacity(opacity)
        // Условно добавляем жест только если свайп включен
        .gesture(
            isSwipeToHideEnabled ? 
            AnyGesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height < 0 {
                            // Позволяем перемещать календарь вверх при свайпе
                            monthCalendarOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        // Если свайп вверх достаточно сильный или достигает половины высоты - скрываем календарь
                        // Добавляем проверку на "половину пути"
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
            // Используем метод вместо прямого присваивания
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
                            selectedDate: $selectedDate,
                            onDateSelected: { date in
                                withAnimation(.spring(response: 0.3)) {
                                    selectedDate = date
                                }
                            },
                            onVisibleMonthChanged: { date in
                                if !calendar.isDate(date, equalTo: visibleMonth, toGranularity: .month) {
                                    visibleMonth = date
                                }
                            }
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
                // Вычисляем индекс месяца для selectedDate
                let monthIdx = getMonthIndex(for: selectedDate)
                // Прокручиваем к месяцу с выбранной датой без анимации и задержки
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
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    let onVisibleMonthChanged: (Date) -> Void

    @ObservedObject private var themeManager = ThemeManager.shared
    
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
                        // Модифицируем ячейку, чтобы она содержала только число
                        ZStack {
                            Circle()
                                .fill(calendar.isDate(day.date, inSameDayAs: selectedDate) ? 
                                      Color.blue : 
                                      themeManager.isDarkMode ? Color(red: 0.098, green: 0.098, blue: 0.098) : Color(red: 0.9, green: 0.9, blue: 0.9))
                                .frame(width: 36, height: 36)
                                .shadow(color: calendar.isDate(day.date, inSameDayAs: selectedDate) ? 
                                        Color.blue.opacity(0.5) : 
                                        Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                            
                            // Дополнительный круг для сегодняшнего дня
                            if Calendar.current.isDateInToday(day.date) && !calendar.isDate(day.date, inSameDayAs: selectedDate) {
                                Circle()
                                    .stroke(Color.blue, lineWidth: 1.5)
                                    .frame(width: 36, height: 36)
                            }
                            
                            // Число
                            Text("\(Calendar.current.component(.day, from: day.date))")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(textColorForDate(day.date, isSelected: calendar.isDate(day.date, inSameDayAs: selectedDate)))
                        }
                        .frame(width: 38, height: 38)
                        .onTapGesture {
                            // Виброотдача при нажатии
                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                            impactMed.impactOccurred()
                            onDateSelected(day.date)
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
    
    private func textColorForDate(_ date: Date, isSelected: Bool) -> Color {
        // Выбранная ячейка имеет белый текст (для контраста с синим фоном)
        if isSelected {
            return .white
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
