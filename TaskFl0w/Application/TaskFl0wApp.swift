//
//  TaskFl0wApp.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Назначаем делегат уведомлений
        UNUserNotificationCenter.current().delegate = self
        
        // Запрашиваем разрешение на уведомления при запуске, если уведомления включены
        if UserDefaults.standard.bool(forKey: "notificationsEnabled") {
            NotificationService.shared.requestNotificationPermission { granted in
                print("Разрешение на уведомления: \(granted)")
            }
        }
        
        return true
    }
    
    // Этот метод позволяет получать уведомления даже когда приложение на переднем плане
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Разрешаем показывать уведомления в переднем плане с баннером, звуком и бейджем
        completionHandler([.banner, .sound, .badge])
    }
}

@main
struct TaskFl0wApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    @AppStorage("isAppAlreadyLaunchedOnce") private var isAppAlreadyLaunchedOnce: Bool = false

    var body: some Scene {
        WindowGroup {
            if !isAppAlreadyLaunchedOnce {
                FirstView()
                    .onDisappear {
                        // Обновляем флаг после исчезновения FirstView
                        isAppAlreadyLaunchedOnce = true
                    }
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                ClockViewIOS()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}


