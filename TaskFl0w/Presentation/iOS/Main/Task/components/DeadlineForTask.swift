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

    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingContent = false
    @State private var selectedTime = Date()
    @State private var hasReminder = false

    // Функция для генерации виброотдачи
    private func generateHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
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

                            Text("Установите deadline для \(selectedTasksCount) задач(и)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(
                                    themeManager.isDarkMode
                                        ? Color.white.opacity(0.7) : Color.secondary
                                )
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 30)
                    .padding(.horizontal, 20)

                    Spacer(minLength: 20)

                    // Календарь
                    MonthCalendarView(
                        selectedDate: $selectedDate,
                        onHideCalendar: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPresented = false
                            }
                        },
                        isSwipeToHideEnabled: false
                    )

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
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Время напоминания")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(
                                        themeManager.isDarkMode
                                            ? Color.white.opacity(0.8) : Color.secondary)

                                DatePicker(
                                    "",
                                    selection: $selectedTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .frame(height: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            themeManager.isDarkMode
                                                ? Color(red: 0.08, green: 0.08, blue: 0.12)
                                                : Color(red: 0.98, green: 0.98, blue: 0.98)
                                        )
                                )
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 30)

                    Spacer(minLength: 30)

                    // Стильные кнопки
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
                        .buttonStyle(ScaleButtonStyle())

                        // Кнопка установки deadline
                        Button {
                            generateHapticFeedback(style: .medium)
                            let finalDate =
                                hasReminder
                                ? combineDateAndTime(date: selectedDate, time: selectedTime)
                                : selectedDate
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
                        .buttonStyle(ScaleButtonStyle())
                        .opacity(selectedTasksCount == 0 ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .opacity(showingContent ? 1 : 0)
            .scaleEffect(showingContent ? 1 : 0.95)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) {
                    showingContent = true
                }
                // Устанавливаем время по умолчанию на 9:00 для напоминания
                let calendar = Calendar.current
                selectedTime =
                    calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
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
}

#Preview {
    DeadlineForTaskView(
        selectedDate: .constant(Date()),
        isPresented: .constant(true),
        selectedTasksCount: 5,
        onSetDeadlineForTasks: { _ in }
    )
}
