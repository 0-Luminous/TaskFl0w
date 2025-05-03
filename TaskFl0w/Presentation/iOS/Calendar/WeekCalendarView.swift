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
    
    var body: some View {
        VStack {
            // Отображение месяца и года
            Text(monthYearFormatter.string(from: selectedDate))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.vertical, 5)
            
            // Прокручиваемые ячейки с днями недели
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(-52...52, id: \.self) { weekIndex in
                            HStack(spacing: 10) {
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
                                }
                            }
                            .id(weekIndex)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 60)
                .onAppear {
                    updateWeekStartDate()
                    scrollProxy.scrollTo(0, anchor: .center)
                }
                .onChange(of: selectedDate) { oldValue, newValue in
                    let selectedWeekIndex = getWeekIndex(for: newValue)
                    if selectedWeekIndex != currentWeekIndex {
                        currentWeekIndex = selectedWeekIndex
                        withAnimation {
                            scrollProxy.scrollTo(selectedWeekIndex, anchor: .center)
                        }
                    }
                }
            }
        }
        .cornerRadius(20)
        .onChange(of: selectedDate) { _, _ in
            updateWeekStartDate()
        }
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
                .foregroundColor(.gray)
            
            // Число
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(width: 40, height: 60)
        .background(isSelected ? Color.blue : Color(UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)))
        .cornerRadius(20)
    }
}

