//
//  FeatureFlags.swift
//  TaskFl0w
//
//  Created by Refactoring on 19/01/25.
//

import Foundation

/// Система feature flags для управления экспериментальными возможностями
struct FeatureFlags {
    
    // MARK: - Architecture Flags
    
    /// Включает новую Redux-подобную архитектуру ClockViewModel
    static var modernClockArchitecture: Bool {
        get {
            UserDefaults.standard.bool(forKey: "feature_modern_clock_architecture")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "feature_modern_clock_architecture")
            NotificationCenter.default.post(
                name: .modernArchitectureToggled,
                object: nil,
                userInfo: ["enabled": newValue]
            )
        }
    }
    
    /// Показывает debug UI для переключения архитектур
    static var showArchitectureToggle: Bool {
        #if DEBUG
        return true
        #else
        return UserDefaults.standard.bool(forKey: "feature_show_architecture_toggle")
        #endif
    }
    
    /// Включает подробное логирование для новой архитектуры
    static var verboseArchitectureLogging: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "feature_verbose_architecture_logging")
        #else
        return false
        #endif
    }
    
    // MARK: - Performance Flags
    
    /// Включает метрики производительности для сравнения архитектур
    static var performanceMetrics: Bool {
        get {
            UserDefaults.standard.bool(forKey: "feature_performance_metrics")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "feature_performance_metrics")
        }
    }
    
    /// Включает A/B тестирование архитектур
    static var abTestingEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: "feature_ab_testing_enabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "feature_ab_testing_enabled")
        }
    }
    
    // MARK: - Development Flags
    
    /// Включает экспериментальные фичи
    static var experimentalFeatures: Bool {
        #if DEBUG
        return true
        #else
        return UserDefaults.standard.bool(forKey: "feature_experimental_features")
        #endif
    }
    
    // MARK: - Helper Methods
    
    /// Сбрасывает все feature flags к значениям по умолчанию
    static func resetToDefaults() {
        let keys = [
            "feature_modern_clock_architecture",
            "feature_show_architecture_toggle",
            "feature_verbose_architecture_logging",
            "feature_performance_metrics",
            "feature_ab_testing_enabled",
            "feature_experimental_features"
        ]
        
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        print("🔄 [FeatureFlags] Reset to defaults")
    }
    
    /// Включает все флаги для разработки
    static func enableAllDevelopmentFlags() {
        #if DEBUG
        modernClockArchitecture = true
        performanceMetrics = true
        
        print("🚀 [FeatureFlags] All development flags enabled")
        #endif
    }
    
    /// Отключает все экспериментальные флаги (safe mode)
    static func disableAllExperimentalFlags() {
        modernClockArchitecture = false
        performanceMetrics = false
        
        print("🛡️ [FeatureFlags] Safe mode activated")
    }
    
    /// Возвращает статус всех флагов для отладки
    static func debugInfo() -> String {
        return """
        🏁 Feature Flags Status:
        
        Architecture:
        • Modern Clock Architecture: \(modernClockArchitecture ? "✅" : "❌")
        • Show Architecture Toggle: \(showArchitectureToggle ? "✅" : "❌")
        • Verbose Logging: \(verboseArchitectureLogging ? "✅" : "❌")
        
        Performance:
        • Performance Metrics: \(performanceMetrics ? "✅" : "❌")
        • A/B Testing: \(abTestingEnabled ? "✅" : "❌")
        
        Development:
        • Experimental Features: \(experimentalFeatures ? "✅" : "❌")
        """
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let modernArchitectureToggled = Notification.Name("modernArchitectureToggled")
    static let featureFlagChanged = Notification.Name("featureFlagChanged")
}

// MARK: - Development Helper

#if DEBUG
extension FeatureFlags {
    /// Быстрое переключение современной архитектуры для тестирования
    static func toggleModernArchitecture() {
        modernClockArchitecture.toggle()
        print("🔄 [FeatureFlags] Modern Architecture: \(modernClockArchitecture ? "ON" : "OFF")")
    }
}
#endif 