//
//  HapticsManager.swift
//  TaskFl0w
//
//  Created by Yan on 15/6/25.
//
import UIKit

struct HapticsManager {

    func triggerLightFeedback() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }
    
    func triggerMediumFeedback() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }
    
    func triggerHeavyFeedback() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }
    
    func triggerSoftFeedback() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }
    
    func triggerRigidFeedback() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }
    
    // MARK: - Selection Feedback (UISelectionFeedbackGenerator)
    
    func triggerSelectionFeedback() {
        let feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator.prepare()
        feedbackGenerator.selectionChanged()
    }
    
    // MARK: - Notification Feedback (UINotificationFeedbackGenerator)
    
    func triggerSuccessFeedback() {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.prepare()
        feedbackGenerator.notificationOccurred(.success)
    }
    
    func triggerWarningFeedback() {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.prepare()
        feedbackGenerator.notificationOccurred(.warning)
    }
    
    func triggerErrorFeedback() {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.prepare()
        feedbackGenerator.notificationOccurred(.error)
    }
    
    // MARK: - Custom Intensity Feedback
    
    /// Настраиваемая интенсивность вибрации
    func triggerCustomIntensityFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: style)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred(intensity: intensity)
    }
    
    // MARK: - Convenience Methods для TaskFl0w
    
    /// Вибрация при перетаскивании элементов
    func triggerDragFeedback() {
        triggerCustomIntensityFeedback(style: .light, intensity: 0.5)
    }
    
    /// Вибрация при завершении задачи
    func triggerTaskCompletedFeedback() {
        triggerSuccessFeedback()
    }
    
    /// Вибрация при удалении задачи
    func triggerTaskDeletedFeedback() {
        triggerWarningFeedback()
    }
    
    /// Вибрация при создании новой задачи
    func triggerTaskCreatedFeedback() {
        triggerMediumFeedback()
    }
    
    /// Вибрация при нажатии кнопки
    func triggerButtonPressFeedback() {
        triggerLightFeedback()
    }
    
    /// Вибрация при навигации
    func triggerNavigationFeedback() {
        triggerSelectionFeedback()
    }
    
    /// Вибрация при ошибке валидации
    func triggerValidationErrorFeedback() {
        triggerErrorFeedback()
    }
    
    /// Вибрация при выборе задачи на часах
    func triggerClockTaskSelectFeedback() {
        triggerSelectionFeedback()
    }
    
    /// Вибрация при перемещении задачи на часах
    func triggerClockTaskMoveFeedback() {
        triggerCustomIntensityFeedback(style: .medium, intensity: 0.7)
    }
    
    /// Вибрация при выборе категории
    func triggerCategorySelectFeedback() {
        triggerMediumFeedback()
    }
    
    /// Вибрация при перетаскивании категории
    func triggerCategoryDragFeedback() {
        triggerDragFeedback()
    }
    
    /// Вибрация при изменении приоритета задачи
    func triggerPriorityChangeFeedback() {
        triggerRigidFeedback()
    }
    
    /// Вибрация при прокрутке таймлайна
    func triggerTimelineScrollFeedback() {
        triggerCustomIntensityFeedback(style: .light, intensity: 0.3)
    }
    
    // MARK: - Advanced Feedback Patterns
    
    /// Двойная вибрация для особых действий
    func triggerDoubleClickFeedback() {
        triggerLightFeedback()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.triggerLightFeedback()
        }
    }
    
    /// Последовательность вибраций
    func triggerSequentialFeedback(feedbacks: [() -> Void], delay: TimeInterval = 0.1) {
        for (index, feedback) in feedbacks.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * delay) {
                feedback()
            }
        }
    }
    
    /// Пульсирующая вибрация для важных уведомлений
    func triggerPulseFeedback(count: Int = 3, delay: TimeInterval = 0.2) {
        let pulses = Array(repeating: { self.triggerMediumFeedback() }, count: count)
        triggerSequentialFeedback(feedbacks: pulses, delay: delay)
    }
    
    // MARK: - Старые методы (для обратной совместимости)
    
    /// Устаревший метод - используйте triggerHeavyFeedback()
    @available(*, deprecated, renamed: "triggerHeavyFeedback")
    func triggerHardFeedback() {
        triggerHeavyFeedback()
    }
}

// MARK: - HapticsManager Singleton (опционально)

extension HapticsManager {
    static let shared = HapticsManager()
}
