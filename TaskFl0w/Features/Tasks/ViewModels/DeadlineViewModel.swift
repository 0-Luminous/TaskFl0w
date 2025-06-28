//
//  DeadlineViewModel.swift
//  TaskFl0w
//
//  Created by AI Assistant on 12/26/25.
//

import SwiftUI
import UserNotifications
import Foundation

@MainActor
class DeadlineViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedDate: Date
    @Published var showingContent = false
    @Published var selectedTime = Date()
    @Published var hasReminder = false
    @Published var selectedReminderOption = "нет"
    @Published var currentDeadline: Date?
    @Published var notificationPermissionGranted = false
    
    // MARK: - Properties
    let selectedTasksCount: Int
    let selectedTasks: [SelectedTaskInfo]
    let existingDeadline: Date?
    let onSetDeadlineForTasks: (Date?) -> Void
    let hapticsManager = HapticsManager.shared
    
    // MARK: - Constants
    let reminderOptions = [
        "нет", "за 5 минут", "за 10 минут", "за 15 минут", "за 20 минут", 
        "за 30 минут", "за 1 час", "за 2 часа", "за 1 день", "за 2 дня"
    ]
    
    // MARK: - Computed Properties
    var timePickerDateRange: ClosedRange<Date> {
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
    
    // MARK: - Initialization
    init(
        selectedDate: Date,
        selectedTasksCount: Int,
        selectedTasks: [SelectedTaskInfo],
        existingDeadline: Date?,
        onSetDeadlineForTasks: @escaping (Date?) -> Void
    ) {
        self.selectedDate = selectedDate
        self.selectedTasksCount = selectedTasksCount
        self.selectedTasks = selectedTasks
        self.existingDeadline = existingDeadline
        self.onSetDeadlineForTasks = onSetDeadlineForTasks
    }
    
    // MARK: - Lifecycle Methods
    func onAppear() {
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
        
        // Проверяем текущие разрешения на уведомления
        checkNotificationPermission()
    }
    
    func onSelectedDateChanged(_ newValue: Date) {
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
    
    // MARK: - Action Methods
    func toggleReminder() {
        hapticsManager.triggerLightFeedback()
        if !hasReminder {
            // Запрашиваем разрешение на уведомления при первом включении
            requestNotificationPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.notificationPermissionGranted = granted
                    if granted {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self?.hasReminder.toggle()
                        }
                    } else {
                        // Показываем alert о необходимости разрешений
                        self?.showNotificationPermissionAlert()
                    }
                }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                hasReminder.toggle()
            }
        }
    }
    
    func selectReminderOption(_ option: String) {
        hapticsManager.triggerLightFeedback()
        selectedReminderOption = option
    }
    
    func cancelReminder() {
        hapticsManager.triggerLightFeedback()
        withAnimation(.easeInOut(duration: 0.3)) {
            hasReminder = false
        }
    }
    
    func setDeadlineWithReminder() {
        hapticsManager.triggerMediumFeedback()
        // Создаем финальную дату deadline
        let baseDate = combineDateAndTime(date: selectedDate, time: selectedTime)
        
        // Удаляем старые уведомления ПЕРЕД созданием новых
        removeExistingNotifications()
        
        // Создаем системное уведомление
        createNotificationForDeadline(baseDate: baseDate, reminderOption: selectedReminderOption)
        
        // Вызываем callback для сохранения в базе данных
        onSetDeadlineForTasks(baseDate)
    }
    
    func setDeadlineWithoutReminder() {
        hapticsManager.triggerMediumFeedback()
        
        // Удаляем старые уведомления для всех задач
        removeExistingNotifications()
        
        // Используем выбранную дату напрямую
        let finalDate = selectedDate
        
        // Всегда вызываем callback для сохранения
        onSetDeadlineForTasks(finalDate)
    }
    
    func resetDeadline() {
        hapticsManager.triggerMediumFeedback()
        
        // Удаляем все уведомления для этих задач
        removeExistingNotifications()
        
        // Сбрасываем текущий deadline
        currentDeadline = nil
        
        // Вызываем callback с nil для удаления deadline из базы данных
        onSetDeadlineForTasks(nil)
        
        print("🗑️ Крайний срок сброшен для \(selectedTasksCount) задач(и)")
    }
    
    // MARK: - Notification Methods
    
    /// Запрашивает разрешение на уведомления
    private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Ошибка запроса разрешений: \(error.localizedDescription)")
            }
            completion(granted)
        }
    }
    
    /// Проверяет текущие разрешения на уведомления
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Показывает alert о необходимости разрешений
    private func showNotificationPermissionAlert() {
        // Можно добавить alert или направить в настройки
        print("⚠️ Разрешения на уведомления не предоставлены")
    }
    
    /// Создает уведомление для deadline
    private func createNotificationForDeadline(baseDate: Date, reminderOption: String) {
        // Удаляем предыдущие уведомления для этих задач
        removeExistingNotifications()
        
        let notificationCenter = UNUserNotificationCenter.current()
        
        // Создаем уведомление на сам deadline
        createDeadlineNotification(date: baseDate, notificationCenter: notificationCenter)
        
        // Создаем уведомление заранее, если выбрано
        if reminderOption != "нет" {
            let reminderDate = calculateReminderDate(baseDate: baseDate, reminderOption: reminderOption)
            createReminderNotification(date: reminderDate, reminderOption: reminderOption, deadlineDate: baseDate, notificationCenter: notificationCenter)
        }
        
        print("📱 Уведомления созданы для deadline: \(baseDate)")
    }
    
    /// Создает уведомление на сам deadline
    private func createDeadlineNotification(date: Date, notificationCenter: UNUserNotificationCenter) {
        let content = UNMutableNotificationContent()
        content.title = "⏰ Крайний срок!"
        
        // Захватываем данные задач в локальные переменные
        let taskCount = selectedTasks.count
        let taskIds = selectedTasks.map { $0.id.uuidString }
        let taskTitles = selectedTasks.map { $0.title }
        
        // Формируем текст с названиями задач
        if taskCount == 1 {
            content.body = "Пора выполнить задачу: \"\(taskTitles.first!)\""
        } else if taskCount <= 3 {
            let titles = taskTitles.joined(separator: ", ")
            content.body = "Пора выполнить задачи: \(titles)"
        } else {
            let firstTasks = taskTitles.prefix(2).joined(separator: ", ")
            content.body = "Пора выполнить задачи: \(firstTasks) и еще \(taskCount - 2)"
        }
        
        content.sound = .default
        content.badge = NSNumber(value: taskCount)
        
        // Добавляем категорию для интерактивных действий
        content.categoryIdentifier = "DEADLINE_CATEGORY"
        
        // Добавляем пользовательские данные
        content.userInfo = [
            "taskIds": taskIds,
            "taskTitles": taskTitles,
            "notificationType": "deadline"
        ]
        
        // Создаем trigger для конкретной даты
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "deadline_\(taskIds.joined(separator: "_"))_\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Ошибка создания уведомления deadline: \(error.localizedDescription)")
            } else {
                print("✅ Уведомление deadline создано на: \(date)")
            }
        }
    }
    
    /// Создает уведомление заранее
    private func createReminderNotification(date: Date, reminderOption: String, deadlineDate: Date, notificationCenter: UNUserNotificationCenter) {
        let content = UNMutableNotificationContent()
        content.title = "🔔 Напоминание о крайнем сроке"
        
        // Захватываем данные задач в локальные переменные
        let taskCount = selectedTasks.count
        let taskIds = selectedTasks.map { $0.id.uuidString }
        let taskTitles = selectedTasks.map { $0.title }
        
        // Формируем текст напоминания с названиями задач
        let timeUntilDeadline = reminderOption.replacingOccurrences(of: "за ", with: "через ")
        
        if taskCount == 1 {
            content.body = "\(timeUntilDeadline) нужно выполнить: \"\(taskTitles.first!)\""
        } else if taskCount <= 3 {
            let titles = taskTitles.joined(separator: "\n• ")
            content.body = "\(timeUntilDeadline) нужно выполнить:\n• \(titles)"
        } else {
            let firstTasks = taskTitles.prefix(3).joined(separator: "\n• ")
            content.body = "\(timeUntilDeadline) нужно выполнить:\n• \(firstTasks)\n• и еще \(taskCount - 3) задач(и)"
        }
        
        content.sound = .default
        content.badge = NSNumber(value: taskCount)
        
        // Добавляем категорию для интерактивных действий
        content.categoryIdentifier = "REMINDER_CATEGORY"
        
        // Добавляем пользовательские данные
        content.userInfo = [
            "taskIds": taskIds,
            "taskTitles": taskTitles,
            "notificationType": "reminder",
            "reminderOption": reminderOption,
            "deadlineDate": deadlineDate.timeIntervalSince1970
        ]
        
        // Создаем trigger для даты напоминания
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "reminder_\(taskIds.joined(separator: "_"))_\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Ошибка создания напоминания: \(error.localizedDescription)")
            } else {
                print("✅ Напоминание создано на: \(date) (\(reminderOption))")
                print("📝 Задачи: \(taskTitles.joined(separator: ", "))")
            }
        }
    }
    
    /// Удаляет существующие уведомления для этих задач
    private func removeExistingNotifications() {
        let taskIds = selectedTasks.map { $0.id.uuidString }
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            var identifiersToRemove: [String] = []
            
            for request in requests {
                // Проверяем по user info данным
                let userInfo = request.content.userInfo
                if let notificationTaskIds = userInfo["taskIds"] as? [String] {
                    // Если есть пересечение с нашими задачами - удаляем
                    if !Set(notificationTaskIds).isDisjoint(with: Set(taskIds)) {
                        identifiersToRemove.append(request.identifier)
                    }
                } else {
                    // Также проверяем по старому формату (по identifier)
                    for taskId in taskIds {
                        if request.identifier.contains(taskId) {
                            identifiersToRemove.append(request.identifier)
                            break
                        }
                    }
                }
            }
            
            if !identifiersToRemove.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
                print("🗑️ Удалено \(identifiersToRemove.count) старых уведомлений для задач")
                print("📋 Удаленные ID: \(identifiersToRemove)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Объединяет дату и время
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
    
    /// Рассчитывает дату напоминания
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
    
    /// Форматирует существующий deadline
    func formatExistingDeadline(_ deadline: Date) -> String {
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
    
    /// Устанавливает время по умолчанию
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
    
    // MARK: - Computed Properties for UI
    
    /// Проверяет, есть ли существующий deadline для отображения кнопки сброса
    var hasExistingDeadline: Bool {
        return currentDeadline != nil || existingDeadline != nil
    }
}
