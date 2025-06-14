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
        
        appearanceScale = 0.0
        appearanceOpacity = 0.0
        appearanceRotation = -15.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + TaskArcConstants.appearanceDelay) {
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) {
                self.appearanceScale = 1.0
                self.appearanceOpacity = 1.0
                self.appearanceRotation = 0.0
            }
        }
    }
    
    func startDisappearanceAnimation(completion: @escaping () -> Void) {
        withAnimation(.easeInOut(duration: 0.6)) {
            appearanceScale = 0.0
            appearanceOpacity = 0.0
            appearanceRotation = 360.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            completion()
        }
    }

    func startAnimatedRemoval(task: TaskOnRing, taskManagement: TaskManagementProtocol) {
        startDisappearanceAnimation {
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