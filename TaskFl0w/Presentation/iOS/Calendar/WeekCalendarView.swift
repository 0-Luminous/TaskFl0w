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
    
    var body: some View {
        VStack {
            // Отображение месяца и года
            Text(monthYearFormatter.string(from: selectedDate))
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 8)
            
            // Навигационные кнопки для переключения недель
            HStack {
                Button(action: { moveWeek(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: { moveWeek(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)
            
            // Дни недели
            HStack {
                ForEach(0..<7, id: \.self) { index in
                    Text(dayNames[index])
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.gray)
                }
            }
            
            // Даты недели
            HStack {
                ForEach(0..<7, id: \.self) { index in
                    let date = calendar.date(byAdding: .day, value: index, to: weekStartDate) ?? Date()
                    
                    VStack {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 16))
                            .frame(width: 30, height: 30)
                            .background(calendar.isDate(date, inSameDayAs: selectedDate) ? Color.blue : Color.clear)
                            .clipShape(Circle())
                            .foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? .white : .white)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
        }
        .onAppear {
            updateWeekStartDate()
        }
        .onChange(of: selectedDate) { _, _ in
            updateWeekStartDate()
        }
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
    
    private func moveWeek(by value: Int) {
        if let newWeekStart = calendar.date(byAdding: .weekOfYear, value: value, to: weekStartDate) {
            weekStartDate = newWeekStart
            // Выбираем первый день новой недели
            selectedDate = newWeekStart
        }
    }
}

