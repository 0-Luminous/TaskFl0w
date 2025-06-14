//
//  TaskFl0wApp.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI
import UserNotifications
import OSLog

// MARK: - App Delegate
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    private let logger = Logger(subsystem: "TaskFl0w", category: "AppDelegate")
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Назначаем делегат уведомлений
        UNUserNotificationCenter.current().delegate = self
        
        // Настраиваем уведомления асинхронно
        Task { @MainActor in
            await setupNotificationsIfNeeded()
        }
        
        logger.info("Приложение запущено успешно")
        return true
    }
    
    @MainActor
    private func setupNotificationsIfNeeded() async {
        let isNotificationsEnabled = UserDefaults.standard.bool(for: .notificationsEnabled, defaultValue: true)
        
        guard isNotificationsEnabled else {
            logger.info("Уведомления отключены в настройках приложения")
            return
        }
        
        do {
            let granted = try await NotificationService.shared.requestNotificationPermission()
            logger.info("Разрешение на уведомления: \(granted)")
        } catch {
            logger.error("Ошибка запроса разрешения на уведомления: \(error.localizedDescription)")
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Разрешаем показывать уведомления в переднем плане с баннером, звуком и бейджем
        completionHandler([.banner, .sound, .badge])
        logger.info("Уведомление показано на переднем плане: \(notification.request.content.title)")
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Обрабатываем действия пользователя с уведомлениями
        let identifier = response.notification.request.identifier
        logger.info("Пользователь взаимодействовал с уведомлением: \(identifier)")
        
        // Здесь можно добавить обработку различных типов уведомлений
        handleNotificationResponse(response)
        
        completionHandler()
    }
    
    private func handleNotificationResponse(_ response: UNNotificationResponse) {
        let identifier = response.notification.request.identifier
        
        if identifier.hasPrefix("task_") {
            // Обработка уведомлений о задачах
            logger.info("Обработка уведомления о задаче")
        } else if identifier.hasPrefix("category_start_") {
            // Обработка уведомлений о начале категории
            logger.info("Обработка уведомления о начале категории")
        }
    }
}

// MARK: - Main App
@main
struct TaskFl0wApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // MARK: - App State
    @AppStorage("isAppAlreadyLaunchedOnce") private var isAppAlreadyLaunchedOnce: Bool = false
    @AppStorage("isAppSetupCompleted") private var isAppSetupCompleted: Bool = false
    
    // MARK: - Core Data
    private let persistenceController: PersistenceController
    
    // MARK: - Initialization
    init() {
        do {
            self.persistenceController = try PersistenceController()
        } catch {
            // В случае критической ошибки с Core Data, логируем и используем in-memory store
            Logger(subsystem: "TaskFl0w", category: "App").critical("Критическая ошибка инициализации Core Data: \(error.localizedDescription)")
            
            do {
                self.persistenceController = try PersistenceController(inMemory: true)
            } catch {
                // Если даже in-memory store не работает, это критическая ошибка
                fatalError("Невозможно инициализировать Core Data: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    // MARK: - Content View
    private struct ContentView: View {
        @AppStorage("isAppAlreadyLaunchedOnce") private var isAppAlreadyLaunchedOnce: Bool = false
        @AppStorage("isAppSetupCompleted") private var isAppSetupCompleted: Bool = false
        
        var body: some View {
            Group {
                if shouldShowFirstView {
                    FirstView()
                        .onDisappear {
                            isAppAlreadyLaunchedOnce = true
                        }
                } else {
                    ClockViewIOS()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: shouldShowFirstView)
        }
        
        private var shouldShowFirstView: Bool {
            !isAppAlreadyLaunchedOnce || !isAppSetupCompleted
        }
    }
    
    // MARK: - Private Methods
    private func setupApp() {
        // Здесь можно добавить дополнительную инициализацию приложения
        // например, миграции данных, настройки аналитики и т.д.
    }
}


