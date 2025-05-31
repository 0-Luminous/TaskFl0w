import AVFoundation
import Foundation
import UIKit
import UserNotifications

protocol NotificationServiceProtocol {
    func requestNotificationPermission(completion: @escaping (Bool) -> Void)
    func requestCriticalAlertsPermission(completion: @escaping (Bool) -> Void)
    func scheduleNotification(for task: TaskOnRing)
    func cancelNotification(for task: TaskOnRing)
    func playSound(_ soundId: String, volume: Float)
    func vibrate()
    func sendCategoryStartNotification(category: TaskCategoryModel)
}

class NotificationService: NotificationServiceProtocol {
    static let shared = NotificationService()

    private var audioPlayer: AVAudioPlayer?
    private let soundFileExtension = "wav"
    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Ошибка настройки аудиосессии: \(error)")
        }
    }

    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) {
            granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Ошибка запроса разрешения на уведомления: \(error)")
                    completion(false)
                } else {
                    completion(granted)
                }
            }
        }
    }

    func requestCriticalAlertsPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) {
            granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Ошибка запроса разрешения на критические уведомления: \(error)")
                    completion(false)
                } else {
                    completion(granted)
                }
            }
        }
    }

    func scheduleNotification(for task: TaskOnRing) {
        let content = UNMutableNotificationContent()
        content.title = "Скоро начнется задача"
        content.body = task.category.rawValue
        content.sound = UNNotificationSound.default

        // Получаем время напоминания из настроек
        let reminderTime = UserDefaults.standard.integer(forKey: "reminderTime")
        let triggerDate = task.startTime.addingTimeInterval(-TimeInterval(reminderTime * 60))

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "task_\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Ошибка планирования уведомления: \(error)")
            }
        }
    }

    func cancelNotification(for task: TaskOnRing) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [
            "task_\(task.id.uuidString)"
        ])
    }

    func playSound(_ soundId: String, volume: Float) {
        guard
            let soundURL = Bundle.main.url(forResource: soundId, withExtension: soundFileExtension)
        else {
            print("Звуковой файл не найден: \(soundId)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.volume = volume
            audioPlayer?.play()
        } catch {
            print("Ошибка воспроизведения звука: \(error)")
        }
    }

    func vibrate() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - Вспомогательные методы

    func sendTestNotification() {
        // Добавляем отладочную информацию
        let notificationsEnabledValue = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        print("DEBUG: Значение notificationsEnabled в UserDefaults: \(notificationsEnabledValue)")
        
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
        
        // Проверяем только статус разрешения системы перед отправкой
        notificationCenter.getNotificationSettings { settings in
            print("DEBUG: Статус авторизации уведомлений: \(settings.authorizationStatus.rawValue)")
            guard settings.authorizationStatus == .authorized else {
                print("Нет системного разрешения на отправку уведомлений: \(settings.authorizationStatus.rawValue)")
                return
            }
            
            self.notificationCenter.add(request) { error in
                if let error = error {
                    print("Ошибка отправки тестового уведомления: \(error)")
                } else {
                    print("Тестовое уведомление успешно отправлено")
                }
            }
        }
    }

    // Отправка уведомления о начале категории
    func sendCategoryStartNotification(category: TaskCategoryModel) {
        // Добавляем отладочную информацию
        let notificationsEnabledValue = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        print("DEBUG: Значение notificationsEnabled в UserDefaults: \(notificationsEnabledValue)")
        
        // ВАЖНО: Убираем проверку UserDefaults для диагностики
        // guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else {
        //     print("Уведомления отключены в настройках приложения")
        //     return
        // }
        
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
        
        // Проверяем статус разрешения перед отправкой
        notificationCenter.getNotificationSettings { settings in
            print("DEBUG: Статус авторизации уведомлений: \(settings.authorizationStatus.rawValue)")
            guard settings.authorizationStatus == .authorized else {
                print("Нет разрешения на отправку уведомлений")
                return
            }
            
            self.notificationCenter.add(request) { error in
                if let error = error {
                    print("Ошибка отправки уведомления о начале категории: \(error)")
                } else {
                    print("Уведомление о начале категории '\(category.rawValue)' успешно отправлено")
                }
            }
        }
    }
}
