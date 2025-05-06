//
//  MonthCalendarView.swift
//  TaskFl0w
//
//  Created by Yan on 6/5/25.
//

import SwiftUI

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
    
    // Добавлена функция обратного вызова для сокрытия календаря
    var onHideCalendar: (() -> Void)?
    
    // Инициализатор для установки начального значения visibleMonth
    init(selectedDate: Binding<Date>, onHideCalendar: (() -> Void)? = nil) {
        self._selectedDate = selectedDate
        self.onHideCalendar = onHideCalendar
        self._visibleMonth = State(initialValue: selectedDate.wrappedValue)
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
                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 10)
        .offset(y: monthCalendarOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height < 0 {
                        monthCalendarOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height < -20 {
                        hideCalendar()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            monthCalendarOffset = 0
                        }
                    }
                }
        )
        .onChange(of: selectedDate) { _, newValue in
            visibleMonth = newValue
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
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            monthCalendarOffset = -200
            onHideCalendar?()
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
                        .foregroundColor(.white.opacity(0.7))
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
                                      Color(red: 0.098, green: 0.098, blue: 0.098))
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
        ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
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
            return .white
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

// Компонент для отображения заголовка с месяцем и годом в виде кнопки
struct MonthYearHeaderButton: View {
    let date: Date
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(formattedDate)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 5)
            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
        }
    }
    
    private var formattedDate: String {
        let rawString = monthYearFormatter.string(from: date)
        // Преобразуем первую букву месяца в верхний регистр
        if let firstChar = rawString.first {
            return String(firstChar).uppercased() + rawString.dropFirst()
        }
        return rawString
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }
}

// Компонент для выбора месяца и года
struct MonthYearPickerView: View {
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    
    private let calendar = Calendar.current
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    
    // Месяцы на русском
    private let months = [
        "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
        "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"
    ]
    
    // Диапазон лет (10 лет до и 10 лет после текущего)
    private var years: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 10)...(currentYear + 10))
    }
    
    init(selectedDate: Binding<Date>, onDateSelected: @escaping (Date) -> Void) {
        self._selectedDate = selectedDate
        self.onDateSelected = onDateSelected
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedDate.wrappedValue)
        
        // Swift month is 1-based, array is 0-based
        self._selectedMonth = State(initialValue: (components.month ?? 1) - 1)
        self._selectedYear = State(initialValue: components.year ?? Calendar.current.component(.year, from: Date()))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Выберите месяц и год")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 8)
            
            HStack {
                // Месяц
                VStack {
                    Text("Месяц")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 4)
                    
                    Picker("Месяц", selection: $selectedMonth) {
                        ForEach(0..<months.count, id: \.self) { index in
                            Text(months[index]).tag(index)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 120)
                    .clipped()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.12, green: 0.12, blue: 0.12))
                    )
                }
                
                // Год
                VStack {
                    Text("Год")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 4)
                    
                    Picker("Год", selection: $selectedYear) {
                        ForEach(years, id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 120)
                    .clipped()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.12, green: 0.12, blue: 0.12))
                    )
                }
            }
            .padding(.horizontal)
            
            // Кнопки
            HStack(spacing: 20) {
                // Кнопка отмены
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        // Просто закрываем пикер без изменений
                        onDateSelected(selectedDate)
                    }
                }) {
                    Text("Отмена")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color(red: 0.3, green: 0.3, blue: 0.3))
                        .cornerRadius(10)
                }
                
                // Кнопка подтверждения
                Button(action: {
                    var components = DateComponents()
                    components.year = selectedYear
                    components.month = selectedMonth + 1 // +1 потому что месяцы в Calendar начинаются с 1
                    components.day = 1
                    
                    if let date = calendar.date(from: components) {
                        onDateSelected(date)
                    }
                }) {
                    Text("Выбрать")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding(.top, 10)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
        )
        .onChange(of: selectedYear) { _, _ in
            updateSelectedDate()
        }
        .onChange(of: selectedMonth) { _, _ in
            updateSelectedDate()
        }
    }
    
    private func updateSelectedDate() {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth + 1
        components.day = 1
        
        if let date = calendar.date(from: components) {
            selectedDate = date
        }
    }
}
