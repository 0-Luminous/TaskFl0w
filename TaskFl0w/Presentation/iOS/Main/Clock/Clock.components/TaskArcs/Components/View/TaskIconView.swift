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
    @ObservedObject var animationManager: TaskArcAnimationManager
    
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
            .scaleEffect(iconScale)
            .opacity(animationManager.appearanceOpacity)
            .rotationEffect(.degrees(animationManager.appearanceRotation * 0.5))
            .animation(.easeInOut(duration: TaskArcConstants.appearanceAnimationDuration), value: geometry.configuration.editingOffset)
    }
    
    private var iconScale: CGFloat {
        animationManager.appearanceScale * 
        TaskArcConstants.iconScaleMultiplier * 
        (animationManager.isPressed ? TaskArcConstants.pressScale : 1.0)
    }
} 