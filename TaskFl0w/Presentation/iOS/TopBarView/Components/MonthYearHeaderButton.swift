//
//  MonthYearHeaderButton.swift
//  TaskFl0w
//
//  Created by Yan on 22/5/25.
//

import SwiftUI
import UIKit

// Компонент для отображения заголовка с месяцем и годом в виде кнопки
struct MonthYearHeaderButton: View {
    let date: Date
    var onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        Button(action: {
            // Виброотдача
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            // Ваш обработчик
            onTap()
        }) {
            HStack {
                Text(formattedDate)
                    .font(.title2)
                    .fontWeight(.regular)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .fill(themeManager.isDarkMode ?
                          Color(red: 0.184, green: 0.184, blue: 0.184) :
                          Color(red: 0.9, green: 0.9, blue: 0.9))
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.7),
                                Color.gray.opacity(0.3),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var formattedDate: String {
        let rawString = monthYearFormatter.string(from: date)
        // Преобразуем первую букву месяца в верхний регистр (только если это нужно)
        if let firstChar = rawString.first {
            return String(firstChar).uppercased() + rawString.dropFirst()
        }
        return rawString
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("LLLL yyyy")
        return formatter
    }
}

// Компонент для выбора месяца и года
struct MonthYearPickerView: View {
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void

    @ObservedObject private var themeManager = ThemeManager.shared
    
    private let calendar = Calendar.current
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    
    // Месяцы на русском — заменим на локализованные значения
    private let months = [
        NSLocalizedString("month.january", comment: ""),
        NSLocalizedString("month.february", comment: ""),
        NSLocalizedString("month.march", comment: ""),
        NSLocalizedString("month.april", comment: ""),
        NSLocalizedString("month.may", comment: ""),
        NSLocalizedString("month.june", comment: ""),
        NSLocalizedString("month.july", comment: ""),
        NSLocalizedString("month.august", comment: ""),
        NSLocalizedString("month.september", comment: ""),
        NSLocalizedString("month.october", comment: ""),
        NSLocalizedString("month.november", comment: ""),
        NSLocalizedString("month.december", comment: "")
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
            Text(NSLocalizedString("monthYearPicker.title", comment: ""))
                .font(.headline)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                .padding(.top, 8)
            
            HStack {
                // Месяц
                VStack {
                    Text(NSLocalizedString("monthYearPicker.month", comment: ""))
                        .font(.subheadline)
                        .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                        .padding(.bottom, 4)
                    
                    Picker(NSLocalizedString("monthYearPicker.month", comment: ""), selection: $selectedMonth) {
                        ForEach(0..<months.count, id: \.self) { index in
                            Text(months[index]).tag(index)
                        }
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 120)
                    .clipped()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeManager.isDarkMode ?
                                  Color(red: 0.12, green: 0.12, blue: 0.12) :
                                  Color(red: 0.8, green: 0.8, blue: 0.8))
                    )
                }
                
                // Год
                VStack {
                    Text(NSLocalizedString("monthYearPicker.year", comment: ""))
                        .font(.subheadline)
                        .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                        .padding(.bottom, 4)
                    
                    Picker(NSLocalizedString("monthYearPicker.year", comment: ""), selection: $selectedYear) {
                        ForEach(years, id: \.self) { year in
                            Text(String(format: "%d", year)).tag(year)
                        }
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 120)
                    .clipped()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeManager.isDarkMode ?
                                  Color(red: 0.12, green: 0.12, blue: 0.12) :
                                  Color(red: 0.8, green: 0.8, blue: 0.8))
                    )
                }
            }
            .padding(.horizontal)
            
            // Кнопки
            HStack(spacing: 20) {
                // Кнопка отмены
                Button(action: {
                    // Виброотдача
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.spring(response: 0.3)) {
                        onDateSelected(selectedDate)
                    }
                }) {
                    HStack {
                        Text(NSLocalizedString("navigation.cancel", comment: ""))
                            .font(.headline)
                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(
                        Capsule()
                            .fill(themeManager.isDarkMode ?
                                  Color(red: 0.184, green: 0.184, blue: 0.184) :
                                  Color(red: 0.95, green: 0.95, blue: 0.95))
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.7),
                                        Color.gray.opacity(0.3),
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Кнопка подтверждения
                Button(action: {
                    // Виброотдача
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()
                    var components = DateComponents()
                    components.year = selectedYear
                    components.month = selectedMonth + 1 // +1 потому что месяцы в Calendar начинаются с 1
                    components.day = 1
                    
                    if let date = calendar.date(from: components) {
                        onDateSelected(date)
                    }
                }) {
                    HStack {
                        Text(NSLocalizedString("monthYearPicker.select", comment: ""))
                            .font(.headline)
                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(
                        Capsule()
                            .fill(themeManager.isDarkMode ?
                                  Color(red: 0.184, green: 0.184, blue: 0.184) :
                                  Color(red: 0.95, green: 0.95, blue: 0.95))
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.7),
                                        Color.gray.opacity(0.3),
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 10)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.isDarkMode ?
                      Color(red: 0.15, green: 0.15, blue: 0.15) :
                      Color(red: 0.9, green: 0.9, blue: 0.9))
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

