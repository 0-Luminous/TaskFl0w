import SwiftUI
import UIKit
import UserNotifications

struct SoundAndNotification: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reminderTime") private var reminderTime = 5  // минут до начала задачи
    @AppStorage("criticalAlertsEnabled") private var criticalAlertsEnabled = false

    @State private var showingPermissionAlert = false

    private let notificationService = NotificationService.shared

    private let reminderTimeOptions = [
        (1, "1 минута"),
        (5, "5 минут"),
        (10, "10 минут"),
        (15, "15 минут"),
        (30, "30 минут"),
        (60, "1 час"),
    ]

    var body: some View {
        Form {
            Section {
                Toggle("Уведомления", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { oldValue, newValue in
                        if newValue {
                            requestNotificationPermission()
                        }
                    }

                if notificationsEnabled {
                    Picker("Напоминать за", selection: $reminderTime) {
                        ForEach(reminderTimeOptions, id: \.0) { option in
                            Text(option.1).tag(option.0)
                        }
                    }

                    Toggle("Важные уведомления", isOn: $criticalAlertsEnabled)
                        .onChange(of: criticalAlertsEnabled) { oldValue, newValue in
                            if newValue {
                                requestCriticalAlertsPermission()
                            }
                        }
                }
            } header: {
                Text("Уведомления")
            } footer: {
                Text("Важные уведомления будут проигрываться даже в режиме «Не беспокоить»")
            }

            Section {
                Button("Проверить уведомление") {
                    sendTestNotification()
                }
                .disabled(!notificationsEnabled)
            } header: {
                Text("Тестирование")
            }
        }
        .navigationTitle("Уведомления")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.backward")
                    Text("Назад")
                }
            }
        }
        .alert("Требуется разрешение", isPresented: $showingPermissionAlert) {
            Button("Настройки") {
                openSettings()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text(
                "Для отправки уведомлений необходимо разрешение. Пожалуйста, откройте настройки приложения и включите уведомления."
            )
        }
    }

    // MARK: - Вспомогательные функции

    private func requestNotificationPermission() {
        notificationService.requestNotificationPermission { granted in
            if !granted {
                showingPermissionAlert = true
            }
        }
    }

    private func requestCriticalAlertsPermission() {
        notificationService.requestCriticalAlertsPermission { granted in
            if !granted {
                showingPermissionAlert = true
            }
        }
    }

    private func sendTestNotification() {
        // Явно устанавливаем значение в UserDefaults, чтобы синхронизировать с интерфейсом
        UserDefaults.standard.set(true, forKey: "notificationsEnabled")
        
        // Просто отправляем запрос на тестовое уведомление
        notificationService.sendTestNotification()
    }

    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

struct SoundAndNotification_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SoundAndNotification()
        }
    }
}
