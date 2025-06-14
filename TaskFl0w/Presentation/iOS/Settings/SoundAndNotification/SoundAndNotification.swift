import SwiftUI
import UIKit
import UserNotifications

struct SoundAndNotification: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reminderTime") private var reminderTime = 5  // минут до начала задачи
    @AppStorage("criticalAlertsEnabled") private var criticalAlertsEnabled = false
    @StateObject private var themeManager = ThemeManager.shared

    @State private var showingPermissionAlert = false

    private let notificationService = NotificationService.shared

    private let reminderTimeOptions = [
        (1, "notifications.time.oneMinute".localized),
        (5, "notifications.time.fiveMinutes".localized),
        (10, "notifications.time.tenMinutes".localized),
        (15, "notifications.time.fifteenMinutes".localized),
        (30, "notifications.time.thirtyMinutes".localized),
        (60, "notifications.time.oneHour".localized),
    ]

    var body: some View {
        Form {
            Section {
                Toggle("notifications.title".localized, isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { oldValue, newValue in
                        if newValue {
                            requestNotificationPermission()
                        }
                    }

                if notificationsEnabled {
                    Picker("notifications.reminderTime".localized, selection: $reminderTime) {
                        ForEach(reminderTimeOptions, id: \.0) { option in
                            Text(option.1).tag(option.0)
                        }
                    }
                }
            } header: {
                Text("notifications.title".localized)
            } footer: {
                Text("notifications.footer".localized)
            }

            Section {
                Button("notifications.testing.testButton".localized) {
                    sendTestNotification()
                }
                .disabled(!notificationsEnabled)
            } header: {
                Text("notifications.testing.title".localized)
            }
        }
        .navigationTitle("notifications.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(.red1)
                    Text("navigation.back".localized)
                    .foregroundColor(.red1)
                }
            }
        }
        .alert("notifications.alert.title".localized, isPresented: $showingPermissionAlert) {
            Button("notifications.alert.settings".localized) {
                openSettings()
            }
            Button("notifications.alert.cancel".localized, role: .cancel) {}
        } message: {
            Text("notifications.alert.message".localized)
        }
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        .background(themeManager.isDarkMode ? 
            Color(red: 0.098, green: 0.098, blue: 0.098) : 
            Color(red: 0.95, green: 0.95, blue: 0.95))
    }

    // MARK: - Вспомогательные функции

    private func requestNotificationPermission() {
        Task { @MainActor in
            do {
                let granted = try await notificationService.requestNotificationPermission()
                if !granted {
                    showingPermissionAlert = true
                }
            } catch {
                print("⚠️ Ошибка запроса разрешения на уведомления: \(error.localizedDescription)")
                showingPermissionAlert = true
            }
        }
    }

    private func requestCriticalAlertsPermission() {
        Task { @MainActor in
            do {
                let granted = try await notificationService.requestCriticalAlertsPermission()
                if !granted {
                    showingPermissionAlert = true
                }
            } catch {
                print("⚠️ Ошибка запроса разрешения на критические уведомления: \(error.localizedDescription)")
                showingPermissionAlert = true
            }
        }
    }

    private func sendTestNotification() {
        // Явно устанавливаем значение в UserDefaults, чтобы синхронизировать с интерфейсом
        UserDefaults.standard.set(true, forKey: "notificationsEnabled")
        
        // Отправляем запрос на тестовое уведомление с proper async handling
        Task { @MainActor in
            do {
                try await notificationService.sendTestNotification()
                print("✅ Тестовое уведомление успешно отправлено")
            } catch {
                print("⚠️ Ошибка отправки тестового уведомления: \(error.localizedDescription)")
                // Можно показать alert пользователю об ошибке
                showingPermissionAlert = true
            }
        }
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
