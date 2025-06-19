import AVFoundation
import Foundation
import UIKit
import UserNotifications
import OSLog

// MARK: - Notification Errors
enum NotificationError: Error, LocalizedError {
    case permissionDenied
    case permissionRequestFailed(Error)
    case schedulingFailed(Error)
    case soundFileNotFound(String)
    case audioPlayerCreationFailed(Error)
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Разрешение на уведомления отклонено"
        case .permissionRequestFailed(let error):
            return "Ошибка запроса разрешения: \(error.localizedDescription)"
        case .schedulingFailed(let error):
            return "Ошибка планирования уведомления: \(error.localizedDescription)"
        case .soundFileNotFound(let fileName):
            return "Звуковой файл не найден: \(fileName)"
        case .audioPlayerCreationFailed(let error):
            return "Ошибка создания аудиоплеера: \(error.localizedDescription)"
        case .invalidConfiguration:
            return "Неверная конфигурация уведомления"
        }
    }
}

// MARK: - Notification Service Protocol
@MainActor
protocol NotificationServiceProtocol: AnyObject {
    func requestNotificationPermission() async throws -> Bool
    func requestCriticalAlertsPermission() async throws -> Bool
    func scheduleNotification(for task: TaskOnRing) async throws
    func cancelNotification(for task: TaskOnRing) async
    func playSound(_ soundId: String, volume: Float) async throws
    func sendCategoryStartNotification(category: TaskCategoryModel) async throws
    func sendTestNotification() async throws
}

// MARK: - Notification Service Implementation
@MainActor
final class NotificationService: NotificationServiceProtocol {
    static let shared = NotificationService()

    // MARK: - Properties
    private var audioPlayer: AVAudioPlayer?
    private let soundFileExtension = "wav"
    private let notificationCenter = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: "TaskFl0w", category: "Notifications")

    // MARK: - Initialization
    private init() {
        setupAudioSession()
    }

    // MARK: - Private Methods
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            logger.info("Аудиосессия настроена успешно")
        } catch {
            logger.error("Ошибка настройки аудиосессии: \(error.localizedDescription)")
        }
    }
    
    private func checkNotificationSettings() async throws -> UNNotificationSettings {
        return await notificationCenter.notificationSettings()
    }
    
    private func isNotificationsEnabled() -> Bool {
        return UserDefaults.standard.bool(for: .notificationsEnabled, defaultValue: true)
    }

    // MARK: - Protocol Implementation
    func requestNotificationPermission() async throws -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            logger.info("Запрос разрешения на уведомления: \(granted)")
            return granted
        } catch {
            logger.error("Ошибка запроса разрешения на уведомления: \(error.localizedDescription)")
            throw NotificationError.permissionRequestFailed(error)
        }
    }

    func requestCriticalAlertsPermission() async throws -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge, .criticalAlert]
            )
            logger.info("Запрос разрешения на критические уведомления: \(granted)")
            return granted
        } catch {
            logger.error("Ошибка запроса разрешения на критические уведомления: \(error.localizedDescription)")
            throw NotificationError.permissionRequestFailed(error)
        }
    }

    func scheduleNotification(for task: TaskOnRing) async throws {
        let settings = try await checkNotificationSettings()
        guard settings.authorizationStatus == .authorized else {
            throw NotificationError.permissionDenied
        }

        let content = UNMutableNotificationContent()
        content.title = "Скоро начнется задача"
        content.body = task.category.rawValue
        content.sound = UNNotificationSound.default

        // Получаем время напоминания из настроек
        let reminderTime = UserDefaults.standard.int(for: .reminderTime, defaultValue: UserDefaultsDefaults.reminderTime)
        let triggerDate = task.startTime.addingTimeInterval(-TimeInterval(reminderTime * 60))

        // Проверяем, что время уведомления в будущем
        guard triggerDate > Date() else {
            logger.warning("Время уведомления в прошлом, пропускаем планирование")
            return
        }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "task_\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            logger.info("Уведомление запланировано для задачи: \(task.category.rawValue)")
        } catch {
            logger.error("Ошибка планирования уведомления: \(error.localizedDescription)")
            throw NotificationError.schedulingFailed(error)
        }
    }

    func cancelNotification(for task: TaskOnRing) async {
        let identifier = "task_\(task.id.uuidString)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        logger.info("Уведомление отменено для задачи: \(task.category.rawValue)")
    }

    func playSound(_ soundId: String, volume: Float) async throws {
        guard let soundURL = Bundle.main.url(forResource: soundId, withExtension: soundFileExtension) else {
            logger.error("Звуковой файл не найден: \(soundId)")
            throw NotificationError.soundFileNotFound(soundId)
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.volume = volume
            audioPlayer?.play()
            logger.info("Воспроизведение звука: \(soundId)")
        } catch {
            logger.error("Ошибка воспроизведения звука: \(error.localizedDescription)")
            throw NotificationError.audioPlayerCreationFailed(error)
        }
    }

    func sendTestNotification() async throws {
        let settings = try await checkNotificationSettings()
        guard settings.authorizationStatus == .authorized else {
            logger.warning("Нет разрешения на отправку тестового уведомления")
            throw NotificationError.permissionDenied
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Тестовое уведомление"
        content.body = "Уведомления работают корректно"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            logger.info("Тестовое уведомление успешно отправлено")
        } catch {
            logger.error("Ошибка отправки тестового уведомления: \(error.localizedDescription)")
            throw NotificationError.schedulingFailed(error)
        }
    }

    func sendCategoryStartNotification(category: TaskCategoryModel) async throws {
        // Проверяем настройки приложения
        guard isNotificationsEnabled() else {
            logger.info("Уведомления отключены в настройках приложения")
            return
        }
        
        let settings = try await checkNotificationSettings()
        guard settings.authorizationStatus == .authorized else {
            logger.warning("Нет разрешения на отправку уведомления о начале категории")
            throw NotificationError.permissionDenied
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Начало категории"
        content.body = category.rawValue
        content.sound = UNNotificationSound.default
        
        // Создаем уведомление с немедленным триггером (1 секунда)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "category_start_\(category.id.uuidString)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            logger.info("Уведомление о начале категории '\(category.rawValue)' успешно отправлено")
        } catch {
            logger.error("Ошибка отправки уведомления о начале категории: \(error.localizedDescription)")
            throw NotificationError.schedulingFailed(error)
        }
    }
}
