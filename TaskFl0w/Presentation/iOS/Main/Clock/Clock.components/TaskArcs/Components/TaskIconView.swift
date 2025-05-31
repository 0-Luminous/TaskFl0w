//
//  TaskIconView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI

struct TaskIconView: View {
    let task: TaskOnRing
    let geometry: TaskArcGeometry
    @Bindable var animationManager: TaskArcAnimationManager
    let hapticsManager: TaskArcHapticsManager
    
    var body: some View {
        Image(systemName: task.category.iconName)
            .font(.system(size: geometry.iconFontSize))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
            .background(
                Circle()
                    .fill(task.category.color)
                    .frame(width: geometry.iconSize, height: geometry.iconSize)
            )
            .position(geometry.iconPosition())
            .scaleEffect(animationManager.currentScale * 1.1)
            .opacity(animationManager.appearanceOpacity)
            .rotationEffect(.degrees(animationManager.appearanceRotation * 0.5))
            .onTapGesture {
                handleTap()
            }
    }
    
    private func handleTap() {
        hapticsManager.triggerSoftFeedback()
        animationManager.triggerPressAnimation()
        // Логика переключения режима редактирования будет здесь
    }
} 