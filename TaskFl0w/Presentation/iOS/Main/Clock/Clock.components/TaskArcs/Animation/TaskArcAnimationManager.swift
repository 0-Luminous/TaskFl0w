//
//  TaskArcAnimationManager.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI

class TaskArcAnimationManager: ObservableObject {
    @Published var appearanceScale: CGFloat = 0.6
    @Published var appearanceOpacity: Double = 1.0
    @Published var appearanceRotation: Double = 0.0
    @Published var hasAppeared: Bool = false
    @Published var isPressed: Bool = false
    
    func startAppearanceAnimation() {
        guard !hasAppeared else { return }
        hasAppeared = true
        
        // Устанавливаем начальные значения
        appearanceScale = 0.0
        appearanceOpacity = 0.0
        appearanceRotation = -15.0
        
        // Запускаем анимацию с задержкой
        DispatchQueue.main.asyncAfter(deadline: .now() + TaskArcConstants.appearanceDelay) {
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) {
                self.appearanceScale = 1.0
                self.appearanceOpacity = 1.0
                self.appearanceRotation = 0.0
            }
        }
    }
    
    func startDisappearanceAnimation(completion: @escaping () -> Void) {
        print("🎬 DEBUG: startDisappearanceAnimation запущена")
        
        // Красивая анимация исчезновения с вращением
        withAnimation(.easeInOut(duration: 0.6)) {
            appearanceScale = 0.0
            appearanceOpacity = 0.0
            appearanceRotation = 360.0 // Полный оборот при исчезновении
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            print("🎬 DEBUG: Анимация исчезновения завершена")
            completion()
        }
    }
    
    // Добавляем новый метод для анимированного удаления
    func startAnimatedRemoval(task: TaskOnRing, taskManagement: TaskManagementProtocol) {
        print("🗑️ DEBUG: Начинаем анимированное удаление задачи: \(task.id)")
        
        startDisappearanceAnimation {
            print("🗑️ DEBUG: Анимация завершена, удаляем задачу из базы данных")
            taskManagement.removeTask(task)
        }
    }
    
    func triggerPressAnimation() {
        withAnimation(.easeOut(duration: TaskArcConstants.pressAnimationDuration)) {
            isPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + TaskArcConstants.pressAnimationDelay) {
            withAnimation(.easeIn(duration: TaskArcConstants.pressAnimationDuration)) {
                self.isPressed = false
            }
        }
    }
    
    var currentScale: CGFloat {
        appearanceScale * (isPressed ? TaskArcConstants.pressScale : 1.0)
    }
}

extension Notification.Name {
    static let startTaskRemovalAnimation = Notification.Name("startTaskRemovalAnimation")
} 