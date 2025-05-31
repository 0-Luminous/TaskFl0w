//
//  TaskArcAnimationManager.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI

@Observable
class TaskArcAnimationManager {
    var appearanceScale: CGFloat = 0.6
    var appearanceOpacity: Double = 1.0
    var appearanceRotation: Double = 0.0
    var hasAppeared: Bool = false
    var isPressed: Bool = false
    
    func startAppearanceAnimation() {
        guard !hasAppeared else { return }
        hasAppeared = true
        
        // Устанавливаем начальные значения
        appearanceScale = 0.0
        appearanceOpacity = 0.0
        appearanceRotation = -15.0
        
        // Запускаем анимацию с задержкой
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) {
                self.appearanceScale = 1.0
                self.appearanceOpacity = 1.0
                self.appearanceRotation = 0.0
            }
        }
    }
    
    func startDisappearanceAnimation(completion: @escaping () -> Void) {
        withAnimation(.easeIn(duration: TaskArcConstants.disappearanceAnimationDuration)) {
            appearanceScale = 0.0
            appearanceOpacity = 0.0
            appearanceRotation = 15.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + TaskArcConstants.disappearanceAnimationDuration) {
            completion()
        }
    }
    
    func triggerPressAnimation() {
        withAnimation(.easeOut(duration: TaskArcConstants.pressAnimationDuration)) {
            isPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeIn(duration: TaskArcConstants.pressAnimationDuration)) {
                self.isPressed = false
            }
        }
    }
    
    var currentScale: CGFloat {
        appearanceScale * (isPressed ? TaskArcConstants.pressScale : 1.0)
    }
} 