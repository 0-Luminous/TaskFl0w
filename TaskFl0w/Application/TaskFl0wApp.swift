//
//  TaskFl0wApp.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI
import OSLog

// MARK: - Main App
@main
struct TaskFl0wApp: App {
    
    // MARK: - App State
    @AppStorage("isAppAlreadyLaunchedOnce") private var isAppAlreadyLaunchedOnce: Bool = false
    @AppStorage("isAppSetupCompleted") private var isAppSetupCompleted: Bool = false
    
    // MARK: - Core Dependencies
    private let diContainer: DIContainer
    private let logger = Logger(subsystem: "TaskFl0w", category: "App")
    
    // MARK: - Initialization
    init() {
        self.diContainer = DIContainer()
        logger.info("TaskFl0w приложение инициализировано с новой архитектурой")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(diContainer.appStateService)
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
                    MainView()
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
        logger.info("Настройка приложения с новой архитектурой")
        
        // Инициализация сервисов через DI Container
        Task {
            await diContainer.appStateService.loadSavedTheme()
        }
    }
}


