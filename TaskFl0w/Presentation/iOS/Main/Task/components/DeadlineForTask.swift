//
//  DeadlineForTask.swift
//  TaskFl0w
//
//  Created by Yan on 12/6/25.
//

import SwiftUI

struct DeadlineForTaskView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    let selectedTasksCount: Int
    let onSetDeadlineForTasks: (Date) -> Void
    
    // Добавляем параметр для текущего deadline
    let existingDeadline: Date?

    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingContent = false
    @State private var selectedTime = Date()
    @State private var hasReminder = false
    @State private var selectedReminderOption = "нет"
    
    // Добавляем локальное состояние для отслеживания установленного deadline
    @State private var currentDeadline: Date?
    
    // Варианты времени для напоминания заранее
    private let reminderOptions = [
        "нет", "за 5 минут", "за 10 минут", "за 15 минут", "за 20 минут", 
        "за 30 минут", "за 1 час", "за 2 часа", "за 1 день", "за 2 дня"
    ]

    // Функция для генерации виброотдачи
    private func generateHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    // Добавляем вычисляемое свойство для диапазона времени
    private var timePickerDateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        
        // Если выбранная дата - сегодня
        if calendar.isDate(selectedDate, inSameDayAs: now) {
            // Минимальное время - текущее время (плюс несколько минут для безопасности)
            let minTime = calendar.date(byAdding: .minute, value: 1, to: now) ?? now
            
            // Максимальное время - конец дня
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: selectedDate) ?? selectedDate
            
            return minTime...endOfDay
        } else {
            // Для будущих дат - можно выбирать любое время в течение дня
            let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: selectedDate) ?? selectedDate
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: selectedDate) ?? selectedDate
            
            return startOfDay...endOfDay
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Градиентный фон
                LinearGradient(
                    gradient: Gradient(
                        colors: themeManager.isDarkMode
                            ? [
                                Color(red: 0.05, green: 0.05, blue: 0.08),
                                Color(red: 0.08, green: 0.08, blue: 0.12),
                            ]
                            : [
                                Color(red: 0.96, green: 0.97, blue: 0.98),
                                Color(red: 0.94, green: 0.95, blue: 0.97),
                            ]
                    ),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Красивый заголовок с иконкой
                    VStack(spacing: 16) {
                        // Иконка deadline
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.red.opacity(0.8),
                                            Color.orange.opacity(0.6),
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 5)

                            Image(systemName: "flag.fill")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                        }

                        VStack(spacing: 8) {
                            Text("Крайний срок")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.isDarkMode ? .white : .primary)

                            Text("Установите крайний срок для \(selectedTasksCount) задач(и)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(
                                    themeManager.isDarkMode
                                        ? Color.white.opacity(0.7) : Color.secondary
                                )
                                .multilineTextAlignment(.center)
                            
                            // Обновляем отображение информации о deadline
                            if let deadline = currentDeadline ?? existingDeadline {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.orange)
                                    
                                    Text("Текущий: \(formatExistingDeadline(deadline))")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.orange)
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    .padding(.top, 30)
                    .padding(.horizontal, 20)

                    Spacer(minLength: 20)

                    // Календарь - скрываем при hasReminder = true
                    if !hasReminder {
                        MonthCalendarView(
                            selectedDate: $selectedDate,
                            deadlineDate: selectedDate,
                            onHideCalendar: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isPresented = false
                                }
                            },
                            isSwipeToHideEnabled: false
                        )
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Кнопка добавления напоминания
                    VStack(spacing: 16) {
                        Button {
                            generateHapticFeedback(style: .light)
                            withAnimation(.easeInOut(duration: 0.3)) {
                                hasReminder.toggle()
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Добавить напоминание")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(themeManager.isDarkMode ? .white : .primary)

                                    Text(hasReminder ? "Напоминание установлено" : "Уведомить перед окончанием задачи")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(
                                            themeManager.isDarkMode
                                                ? Color.white.opacity(0.7) : Color.secondary)
                                }

                                Spacer()

                                Image(systemName: hasReminder ? "bell.fill" : "bell")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(hasReminder ? .orange : (themeManager.isDarkMode ? .white.opacity(0.7) : .secondary))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        hasReminder 
                                            ? (themeManager.isDarkMode 
                                                ? Color.orange.opacity(0.1) 
                                                : Color.orange.opacity(0.05))
                                            : (themeManager.isDarkMode
                                                ? Color(red: 0.08, green: 0.08, blue: 0.12)
                                                : Color(red: 0.98, green: 0.98, blue: 0.98))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                hasReminder 
                                                    ? Color.orange.opacity(0.3)
                                                    : (themeManager.isDarkMode
                                                        ? Color.white.opacity(0.1)
                                                        : Color.gray.opacity(0.2)),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        if hasReminder {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Время напоминания")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(themeManager.isDarkMode ? .white : .primary)
                                    .frame(maxWidth: .infinity, alignment: .center)

                                DatePicker(
                                    "",
                                    selection: $selectedTime,
                                    in: timePickerDateRange,
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            themeManager.isDarkMode
                                                ? Color(red: 0.08, green: 0.08, blue: 0.12)
                                                : Color(red: 0.98, green: 0.98, blue: 0.98)
                                        )
                                )
                                
                                // Выбор времени заблаговременного напоминания
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Напомнить заранее")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(themeManager.isDarkMode ? .white : .primary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(reminderOptions, id: \.self) { option in
                                                Button {
                                                    generateHapticFeedback(style: .light)
                                                    selectedReminderOption = option
                                                } label: {
                                                    Text(option)
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(
                                                            selectedReminderOption == option 
                                                                ? .white 
                                                                : (themeManager.isDarkMode ? .white.opacity(0.8) : .primary)
                                                        )
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 8)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 20)
                                                                .fill(
                                                                    selectedReminderOption == option
                                                                        ? LinearGradient(
                                                                            gradient: Gradient(colors: [
                                                                                Color.orange.opacity(0.8),
                                                                                Color.red.opacity(0.6)
                                                                            ]),
                                                                            startPoint: .topLeading,
                                                                            endPoint: .bottomTrailing
                                                                        )
                                                                        : LinearGradient(
                                                                            gradient: Gradient(colors: [
                                                                                themeManager.isDarkMode 
                                                                                    ? Color(red: 0.12, green: 0.12, blue: 0.15)
                                                                                    : Color(red: 0.96, green: 0.96, blue: 0.98),
                                                                                themeManager.isDarkMode 
                                                                                    ? Color(red: 0.08, green: 0.08, blue: 0.12)
                                                                                    : Color(red: 0.94, green: 0.94, blue: 0.96)
                                                                            ]),
                                                                            startPoint: .topLeading,
                                                                            endPoint: .bottomTrailing
                                                                        )
                                                                )
                                                                .overlay(
                                                                    RoundedRectangle(cornerRadius: 20)
                                                                        .stroke(
                                                                            selectedReminderOption == option
                                                                                ? Color.orange.opacity(0.4)
                                                                                : (themeManager.isDarkMode 
                                                                                    ? Color.white.opacity(0.1)
                                                                                    : Color.gray.opacity(0.2)),
                                                                            lineWidth: 1
                                                                        )
                                                                )
                                                        )
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                        .padding(.horizontal, 4)
                                    }
                                }
                                
                                // Кнопки "Отмена" и "Установить" для режима напоминания
                                HStack(spacing: 16) {
                                    // Кнопка отмены
                                    Button {
                                        generateHapticFeedback(style: .light)
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            hasReminder = false
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 16, weight: .semibold))
                                            Text("Отмена")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(themeManager.isDarkMode ? .white : .primary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(
                                                    themeManager.isDarkMode
                                                        ? Color(red: 0.15, green: 0.15, blue: 0.18)
                                                        : Color(red: 0.95, green: 0.95, blue: 0.97)
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(
                                                            themeManager.isDarkMode
                                                                ? Color.white.opacity(0.1)
                                                                : Color.gray.opacity(0.2),
                                                            lineWidth: 1
                                                        )
                                                )
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    // Кнопка установки для режима напоминания
                                    Button {
                                        generateHapticFeedback(style: .medium)
                                        // Создаем финальную дату deadline без вычитания времени напоминания
                                        let baseDate = combineDateAndTime(date: selectedDate, time: selectedTime)
                                        
                                        // Если нужно настроить напоминание заранее, это должно быть отдельно
                                        if selectedReminderOption != "нет" {
                                            let reminderDate = calculateReminderDate(baseDate: baseDate, reminderOption: selectedReminderOption)
                                            print("📅 Deadline установлен на: \(baseDate)")
                                            print("⏰ Напоминание запланировано на: \(reminderDate)")
                                            // Здесь в будущем можно добавить логику создания локального уведомления
                                        }
                                        
                                        // Обновляем локальное состояние для показа информации о deadline
                                        currentDeadline = baseDate
                                        
                                        // Обновляем selectedDate чтобы календарь показывал установленную дату
                                        selectedDate = baseDate
                                        
                                        // Возвращаемся к календарю вместо закрытия экрана
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            hasReminder = false
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 16, weight: .semibold))
                                            Text("Установить")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [
                                                            Color.green, Color.blue.opacity(0.8),
                                                        ]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .shadow(
                                                    color: Color.green.opacity(0.4),
                                                    radius: 8,
                                                    x: 0,
                                                    y: 4
                                                )
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.top, 20)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 30)

                    Spacer(minLength: 30)

                    // Стильные кнопки - скрываем при hasReminder = true
                    if !hasReminder {
                        HStack(spacing: 16) {
                            // Кнопка отмены
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isPresented = false
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Отмена")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(themeManager.isDarkMode ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            themeManager.isDarkMode
                                                ? Color(red: 0.15, green: 0.15, blue: 0.18)
                                                : Color(red: 0.95, green: 0.95, blue: 0.97)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(
                                                    themeManager.isDarkMode
                                                        ? Color.white.opacity(0.1)
                                                        : Color.gray.opacity(0.2),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())

                            // Кнопка установки deadline без напоминания
                            Button {
                                generateHapticFeedback(style: .medium)
                                
                                // Определяем финальную дату в зависимости от того, было ли установлено время
                                let finalDate: Date
                                if let current = currentDeadline {
                                    // Если время было установлено через напоминание, используем его
                                    finalDate = current
                                } else {
                                    // Иначе используем только выбранную дату без времени (00:00)
                                    finalDate = selectedDate
                                }
                                
                                // Обновляем локальное состояние для показа информации о deadline
                                currentDeadline = finalDate
                                
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    onSetDeadlineForTasks(finalDate)
                                    isPresented = false
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "flag.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Установить")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            selectedTasksCount == 0
                                                ? LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.gray.opacity(0.5),
                                                        Color.gray.opacity(0.3),
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                                : LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.red, Color.orange,
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                        )
                                        .shadow(
                                            color: selectedTasksCount == 0
                                                ? Color.clear : Color.red.opacity(0.4),
                                            radius: 8,
                                            x: 0,
                                            y: 4
                                        )
                                )
                            }
                            .disabled(selectedTasksCount == 0)
                            .buttonStyle(PlainButtonStyle())
                            .opacity(selectedTasksCount == 0 ? 0.6 : 1.0)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .navigationBarHidden(true)
            .opacity(showingContent ? 1 : 0)
            .scaleEffect(showingContent ? 1 : 0.95)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) {
                    showingContent = true
                }
                
                // Инициализируем currentDeadline
                currentDeadline = existingDeadline
                
                // Если есть существующий deadline, устанавливаем время от него
                if let existingDeadline = existingDeadline {
                    selectedTime = existingDeadline
                } else {
                    // Устанавливаем время с учетом ограничений
                    setDefaultTime()
                }
            }
            .onChange(of: selectedDate) { _, newValue in
                // Если время становится недоступным при новой дате, обновляем его
                let calendar = Calendar.current
                let now = Date()
                
                if calendar.isDate(newValue, inSameDayAs: now) {
                    // Если выбрали сегодняшнюю дату и текущее время уже прошло
                    if selectedTime <= now {
                        selectedTime = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    // Функция для объединения даты и времени
    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = 0

        return calendar.date(from: combinedComponents) ?? date
    }

    // Функция для расчета даты напоминания
    private func calculateReminderDate(baseDate: Date, reminderOption: String) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: baseDate)
        
        switch reminderOption {
        case "за 5 минут":
            components.minute = components.minute! - 5
        case "за 10 минут":
            components.minute = components.minute! - 10
        case "за 15 минут":
            components.minute = components.minute! - 15
        case "за 20 минут":
            components.minute = components.minute! - 20
        case "за 30 минут":
            components.minute = components.minute! - 30
        case "за 1 час":
            components.hour = components.hour! - 1
        case "за 2 часа":
            components.hour = components.hour! - 2
        case "за 1 день":
            components.day = components.day! - 1
        case "за 2 дня":
            components.day = components.day! - 2
        default:
            break
        }
        
        return calendar.date(from: components) ?? baseDate
    }

    // Обновляем метод для форматирования существующего deadline
    private func formatExistingDeadline(_ deadline: Date) -> String {
        let calendar = Calendar.current
        
        // Проверяем, установлено ли конкретное время (не 00:00)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: deadline)
        let hasSpecificTime = timeComponents.hour != 0 || timeComponents.minute != 0
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        if hasSpecificTime {
            formatter.timeStyle = .short
        } else {
            formatter.timeStyle = .none
        }
        
        return formatter.string(from: deadline)
    }

    // Добавляем метод для установки времени по умолчанию
    private func setDefaultTime() {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDate(selectedDate, inSameDayAs: now) {
            // Для сегодняшней даты - устанавливаем время через час от текущего
            selectedTime = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        } else {
            // Для будущих дат - устанавливаем 9:00
            selectedTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        }
    }
}

#Preview {
    DeadlineForTaskView(
        selectedDate: .constant(Date()),
        isPresented: .constant(true),
        selectedTasksCount: 5,
        onSetDeadlineForTasks: { _ in },
        existingDeadline: Date() // Добавляем для preview
    )
}
