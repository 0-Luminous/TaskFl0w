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
    @State private var weekCalendarOffset: CGFloat = 0 // Добавлено из ClockViewIOS
    
    // Добавлена функция обратного вызова для сокрытия календаря
    var onHideCalendar: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 10) {
            // Отображение месяца и года отдельно от календаря
            MonthYearHeader(date: selectedDate)
            
            // Секция с календарем
            CalendarSection
                .cornerRadius(16)
        }
        .padding(.horizontal, 14) // Добавлено из ClockViewIOS
        .padding(.vertical, 8) // Добавлено из ClockViewIOS
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                .shadow(color: .black.opacity(0.3), radius: 5)
        ) // Добавлено из ClockViewIOS
        .padding(.horizontal, 10) // Добавлено из ClockViewIOS
        .offset(y: weekCalendarOffset) // Добавлено из ClockViewIOS
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Только если календарь уже показан и свайп вверх
                    if value.translation.height < 0 {
                        weekCalendarOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    // Если сделан свайп вверх, скрываем календарь
                    if value.translation.height < -20 {
                        hideCalendar()
                    } else {
                        // Возвращаем в исходное положение
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            weekCalendarOffset = 0
                        }
                    }
                }
        ) // Добавлено из ClockViewIOS
        .onChange(of: selectedDate) { _, _ in
            // Автоматически скрываем календарь после выбора даты
            hideCalendar()
            updateWeekStartDate()
        } // Обновлено с учетом ClockViewIOS
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
                                    selectedDate = date
                                }
                                // Используем саму дату как идентификатор ячейки
                                .id("\(calendar.component(.year, from: date))-\(calendar.component(.month, from: date))-\(calendar.component(.day, from: date))")
                            }
                        }
                        .id(weekIndex)
                    }
                }
                .padding(.horizontal, 2) // Минимальный отступ от края экрана
            }
            // Расширяем ScrollView, чтобы она занимала всю доступную ширину
            .frame(maxWidth: .infinity)
            .frame(height: 65)
            .clipShape(Rectangle())
            .onAppear {
                updateWeekStartDate()
                // При первом появлении прокручиваем к текущей неделе
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        scrollProxy.scrollTo(0, anchor: .center)
                    }
                }
            }
            .onChange(of: selectedDate) { oldValue, newValue in
                let selectedWeekIndex = getWeekIndex(for: newValue)
                
                // Сначала всегда обновляем currentWeekIndex
                currentWeekIndex = selectedWeekIndex
                
                // Создаем ID даты, который будем использовать для прокрутки
                let dateId = "\(calendar.component(.year, from: newValue))-\(calendar.component(.month, from: newValue))-\(calendar.component(.day, from: newValue))"
                
                // Если изменился индекс недели, сначала прокручиваем к неделе
                if selectedWeekIndex != getWeekIndex(for: oldValue) {
                    withAnimation {
                        scrollProxy.scrollTo(selectedWeekIndex, anchor: .center)
                    }
                    
                    // После прокрутки к неделе используем небольшую задержку
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation {
                            scrollProxy.scrollTo(dateId, anchor: .center)
                        }
                    }
                } else {
                    // Если мы в той же неделе, просто прокручиваем к дате
                    withAnimation {
                        scrollProxy.scrollTo(dateId, anchor: .center)
                    }
                }
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
        formatter.dateFormat = "MMMM yyyy"
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
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            weekCalendarOffset = -200
            // Вызываем колбэк для сообщения родительскому компоненту о необходимости скрыть календарь
            onHideCalendar?()
        }
    }
}

// Компонент для отображения заголовка с месяцем и годом
struct MonthYearHeader: View {
    let date: Date
    
    var body: some View {
        Text(monthYearFormatter.string(from: date))
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.vertical, 5)
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
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
                .foregroundColor(isSelected ? .black : .gray)
            
            // Число
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(width: 40, height: 60)
        .background(isSelected ? Color.blue : Color(red: 0.098, green: 0.098, blue: 0.098))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isToday && !isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
    
    // Проверяем, является ли дата сегодняшней
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

