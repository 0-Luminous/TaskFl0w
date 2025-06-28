//
//  DeadlineForTask.swift
//  TaskFl0w
//
//  Created by Yan on 12/6/25.
//

import SwiftUI
import UserNotifications

// Добавляем структуру для информации о выбранных задачах
struct SelectedTaskInfo {
    let id: UUID
    let title: String
    let priority: TaskPriority
}

struct DeadlineForTaskView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    @StateObject private var viewModel: DeadlineViewModel
    @ObservedObject private var themeManager = ThemeManager.shared

    // MARK: - Initialization
    init(
        selectedDate: Binding<Date>,
        isPresented: Binding<Bool>,
        selectedTasksCount: Int,
        selectedTasks: [SelectedTaskInfo],
        onSetDeadlineForTasks: @escaping (Date?) -> Void,
        existingDeadline: Date?
    ) {
        self._selectedDate = selectedDate
        self._isPresented = isPresented
        self._viewModel = StateObject(wrappedValue: DeadlineViewModel(
            selectedDate: selectedDate.wrappedValue,
            selectedTasksCount: selectedTasksCount,
            selectedTasks: selectedTasks,
            existingDeadline: existingDeadline,
            onSetDeadlineForTasks: onSetDeadlineForTasks
        ))
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Градиентный фон
                backgroundGradient
                
                VStack(spacing: 0) {
                    // Красивый заголовок с иконкой
                    headerSection
                    
                    Spacer(minLength: 20)

                    // Календарь - скрываем при hasReminder = true
                    if !viewModel.hasReminder {
                        calendarSection
                    }

                    // Кнопка добавления напоминания
                    reminderSection
                    
                    Spacer(minLength: 30)

                    // Стильные кнопки - скрываем при hasReminder = true
                    if !viewModel.hasReminder {
                        actionButtonsSection
                    }
                }
            }
            .navigationBarHidden(true)
            .opacity(viewModel.showingContent ? 1 : 0)
            .scaleEffect(viewModel.showingContent ? 1 : 0.95)
            .onAppear {
                viewModel.onAppear()
            }
            .onChange(of: viewModel.selectedDate) { _, newValue in
                selectedDate = newValue
                viewModel.onSelectedDateChanged(newValue)
            }
            .onChange(of: selectedDate) { _, newValue in
                viewModel.selectedDate = newValue
                viewModel.onSelectedDateChanged(newValue)
            }
        }
        .presentationDetents([.large])
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
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
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Иконка deadline
            deadlineIcon
            
            VStack(spacing: 8) {
                Text("Крайний срок")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.isDarkMode ? .white : .primary)

                Text("Установите крайний срок для \(viewModel.selectedTasksCount) задач(и)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(
                        themeManager.isDarkMode
                            ? Color.white.opacity(0.7) : Color.secondary
                    )
                    .multilineTextAlignment(.center)
                
                // Отображение информации о deadline
                existingDeadlineInfo
            }
        }
        .padding(.top, 30)
        .padding(.horizontal, 20)
    }
    
    private var deadlineIcon: some View {
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
    }
    
    @ViewBuilder
    private var existingDeadlineInfo: some View {
        if let deadline = viewModel.currentDeadline ?? viewModel.existingDeadline {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                    
                    Text("Текущий: \(viewModel.formatExistingDeadline(deadline))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                }
                
                // Кнопка сброса deadline
                resetDeadlineButton
            }
            .padding(.top, 4)
        }
    }
    
    private var resetDeadlineButton: some View {
        Button {
            viewModel.resetDeadline()
            withAnimation(.easeInOut(duration: 0.3)) {
                isPresented = false
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 12, weight: .medium))
                
                Text("Сбросить срок")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.red.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        themeManager.isDarkMode
                            ? Color.red.opacity(0.1)
                            : Color.red.opacity(0.05)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Calendar Section
    
    private var calendarSection: some View {
        MonthCalendarView(
            selectedDate: $viewModel.selectedDate,
            deadlineDate: viewModel.selectedDate,
            onHideCalendar: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
            },
            isSwipeToHideEnabled: false
        )
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Reminder Section
    
    private var reminderSection: some View {
        VStack(spacing: 16) {
            reminderToggleButton
            
            if viewModel.hasReminder {
                reminderContentView
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 30)
    }
    
    private var reminderToggleButton: some View {
        Button {
            viewModel.toggleReminder()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Добавить напоминание")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.isDarkMode ? .white : .primary)

                    Text(viewModel.hasReminder ? "Напоминание установлено" : "Уведомить перед окончанием задачи")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(
                            themeManager.isDarkMode
                                ? Color.white.opacity(0.7) : Color.secondary)
                }

                Spacer()

                Image(systemName: viewModel.hasReminder ? "bell.fill" : "bell")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(viewModel.hasReminder ? .orange : (themeManager.isDarkMode ? .white.opacity(0.7) : .secondary))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(reminderToggleBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var reminderToggleBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                viewModel.hasReminder 
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
                        viewModel.hasReminder 
                            ? Color.orange.opacity(0.3)
                            : (themeManager.isDarkMode
                                ? Color.white.opacity(0.1)
                                : Color.gray.opacity(0.2)),
                        lineWidth: 1
                    )
            )
    }
    
    private var reminderContentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Время напоминания")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.isDarkMode ? .white : .primary)
                .frame(maxWidth: .infinity, alignment: .center)

            timePicker
            reminderOptionsSection
            reminderActionButtons
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    private var timePicker: some View {
        DatePicker(
            "",
            selection: $viewModel.selectedTime,
            in: viewModel.timePickerDateRange,
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
    }
    
    // MARK: - Reminder Options
    
    private var reminderOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Напомнить заранее")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.isDarkMode ? .white : .primary)
                .frame(maxWidth: .infinity, alignment: .center)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.reminderOptions, id: \.self) { option in
                        reminderOptionButton(option: option)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private func reminderOptionButton(option: String) -> some View {
        Button {
            viewModel.selectReminderOption(option)
        } label: {
            Text(option)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(
                    viewModel.selectedReminderOption == option 
                        ? .white 
                        : (themeManager.isDarkMode ? .white.opacity(0.8) : .primary)
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(reminderOptionBackground(isSelected: viewModel.selectedReminderOption == option))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func reminderOptionBackground(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                isSelected
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
                        isSelected
                            ? Color.orange.opacity(0.4)
                            : (themeManager.isDarkMode 
                                ? Color.white.opacity(0.1)
                                : Color.gray.opacity(0.2)),
                        lineWidth: 1
                    )
            )
    }
    
    // MARK: - Action Buttons
    
    private var reminderActionButtons: some View {
        HStack(spacing: 16) {
            cancelReminderButton
            setReminderButton
        }
        .padding(.top, 20)
    }
    
    private var cancelReminderButton: some View {
        Button {
            viewModel.cancelReminder()
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
            .background(secondaryButtonBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var setReminderButton: some View {
        Button {
            viewModel.setDeadlineWithReminder()
            withAnimation(.easeInOut(duration: 0.3)) {
                isPresented = false
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
            .background(successButtonBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Кнопка сброса, если есть существующий deadline
            if viewModel.hasExistingDeadline {
                resetDeadlineMainButton
            }
            
            HStack(spacing: 16) {
                cancelButton
                setDeadlineButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
        .transition(.scale.combined(with: .opacity))
    }
    
    private var resetDeadlineMainButton: some View {
        Button {
            viewModel.resetDeadline()
            withAnimation(.easeInOut(duration: 0.3)) {
                isPresented = false
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Сбросить крайний срок")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(resetButtonBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var resetButtonBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.red.opacity(0.8),
                        Color.red.opacity(0.6),
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(
                color: Color.red.opacity(0.3),
                radius: 6,
                x: 0,
                y: 3
            )
    }
    
    private var cancelButton: some View {
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
            .background(secondaryButtonBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var setDeadlineButton: some View {
        Button {
            viewModel.setDeadlineWithoutReminder()
            withAnimation(.easeInOut(duration: 0.3)) {
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
            .background(primaryButtonBackground)
        }
        .disabled(viewModel.selectedTasksCount == 0)
        .buttonStyle(PlainButtonStyle())
        .opacity(viewModel.selectedTasksCount == 0 ? 0.6 : 1.0)
    }
    
    // MARK: - Button Backgrounds
    
    private var secondaryButtonBackground: some View {
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
    }
    
    private var successButtonBackground: some View {
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
    }
}

#Preview {
    DeadlineForTaskView(
        selectedDate: .constant(Date()),
        isPresented: .constant(true),
        selectedTasksCount: 2,
        selectedTasks: [
            SelectedTaskInfo(id: UUID(), title: "Купить продукты", priority: .high),
            SelectedTaskInfo(id: UUID(), title: "Подготовить презентацию", priority: .medium)
        ],
        onSetDeadlineForTasks: { deadline in
            if let deadline = deadline {
                print("Установлен deadline: \(deadline)")
            } else {
                print("Deadline сброшен")
            }
        },
        existingDeadline: Date()
    )
}
