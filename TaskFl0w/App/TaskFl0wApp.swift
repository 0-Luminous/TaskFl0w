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
    @StateObject private var sharedState = SharedStateService()
    private let logger = Logger(subsystem: "TaskFl0w", category: "App")
    
    // MARK: - Initialization
    init() {
        logger.info("TaskFl0w приложение инициализировано с максимально упрощенной архитектурой")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sharedState)
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
                // if shouldShowFirstView {
                //     FirstView()
                //         .onDisappear {
                //             isAppAlreadyLaunchedOnce = true
                //         }
                // } else {
                    ClockViewIOS()
                // }
            }
            .animation(.easeInOut(duration: 0.3), value: shouldShowFirstView)
        }
        
        private var shouldShowFirstView: Bool {
            !isAppAlreadyLaunchedOnce || !isAppSetupCompleted
        }
    }
    
    // MARK: - Private Methods
    private func setupApp() {
        logger.info("Настройка приложения завершена")
        logger.debug("SharedState готов к работе")
    }
}


