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
        content.body = task.title
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

        notificationCenter.add(request) { error in
            if let error = error {
                print("Ошибка отправки тестового уведомления: \(error)")
            }
        }
    }
}
