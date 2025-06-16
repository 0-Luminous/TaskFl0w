//
//  AppStateService.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation
import SwiftUI
import Combine
import OSLog

/// Упрощенный сервис управления состоянием приложения
@MainActor
final class AppStateService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedDate = Date()
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "TaskFl0w", category: "AppStateService")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
        logger.info("AppStateService инициализирован")
    }
    
    // MARK: - Public Methods
    
    /// Очищает ошибки
    func clearError() {
        error = nil
    }
    
    /// Устанавливает состояние загрузки
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    /// Устанавливает ошибку
    func setError(_ error: Error?) {
        self.error = error
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Логируем изменения даты
        $selectedDate
            .sink { [weak self] date in
                self?.logger.debug("Выбрана дата: \(date)")
            }
            .store(in: &cancellables)
    }
} 