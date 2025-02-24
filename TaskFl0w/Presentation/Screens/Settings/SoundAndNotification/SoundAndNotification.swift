import SwiftUI
import UIKit

struct SoundAndNotification: View {
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reminderTime") private var reminderTime = 5 // минут до начала задачи
    @AppStorage("soundVolume") private var soundVolume = 0.7
    @AppStorage("selectedSoundId") private var selectedSoundId = "bell"
    @AppStorage("vibrationEnabled") private var vibrationEnabled = true
    @AppStorage("criticalAlertsEnabled") private var criticalAlertsEnabled = false
    
    @State private var showingPermissionAlert = false
    @State private var isTestingSoundEnabled = false
    
    private let notificationService = NotificationService.shared
    
    private let availableSounds = [
        ("bell", "Колокольчик"),
        ("chime", "Перезвон"),
        ("crystal", "Кристалл"),
        ("digital", "Цифровой"),
        ("gentle", "Нежный"),
        ("minimal", "Минимальный")
    ]
    
    private let reminderTimeOptions = [
        (1, "1 минута"),
        (5, "5 минут"),
        (10, "10 минут"),
        (15, "15 минут"),
        (30, "30 минут"),
        (60, "1 час")
    ]
    
    var body: some View {
        Form {
            Section {
                Toggle("Звуки", isOn: $soundEnabled)
                    .onChange(of: soundEnabled) { newValue in
                        if newValue {
                            playTestSound()
                        }
                    }
                
                if soundEnabled {
                    VStack {
                        HStack {
                            Text("Громкость")
                            Spacer()
                            Text("\(Int(soundVolume * 100))%")
                        }
                        
                        Slider(value: $soundVolume, in: 0...1) { editing in
                            if !editing && isTestingSoundEnabled {
                                playTestSound()
                            }
                        }
                    }
                    
                    Picker("Звук уведомления", selection: $selectedSoundId) {
                        ForEach(availableSounds, id: \.0) { sound in
                            Text(sound.1).tag(sound.0)
                        }
                    }
                    .onChange(of: selectedSoundId) { _ in
                        playTestSound()
                    }
                    
                    Toggle("Вибрация", isOn: $vibrationEnabled)
                }
            } header: {
                Text("Звуки и тактильный отклик")
            } footer: {
                Text("Выберите звук уведомления и настройте громкость")
            }
            
            Section {
                Toggle("Уведомления", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { newValue in
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
                        .onChange(of: criticalAlertsEnabled) { newValue in
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
                Button("Проверить звук") {
                    playTestSound()
                }
                .disabled(!soundEnabled)
                
                Button("Проверить уведомление") {
                    sendTestNotification()
                }
                .disabled(!notificationsEnabled)
            } header: {
                Text("Тестирование")
            }
        }
        .navigationTitle("Звук и уведомления")
        .alert("Требуется разрешение", isPresented: $showingPermissionAlert) {
            Button("Настройки") {
                openSettings()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Для отправки уведомлений необходимо разрешение. Пожалуйста, откройте настройки приложения и включите уведомления.")
        }
    }
    
    // MARK: - Вспомогательные функции
    
    private func playTestSound() {
        guard soundEnabled else { return }
        notificationService.playSound(selectedSoundId, volume: Float(soundVolume))
        
        if vibrationEnabled {
            notificationService.vibrate()
        }
    }
    
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
        guard notificationsEnabled else { return }
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
