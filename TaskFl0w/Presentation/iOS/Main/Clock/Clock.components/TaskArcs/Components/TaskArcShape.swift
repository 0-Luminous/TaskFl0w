//
//  TaskArcShape.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI

struct TaskArcShape: View {
    let geometry: TaskArcGeometry
    let timeFormatter: DateFormatter
    @ObservedObject var animationManager: TaskArcAnimationManager
    
    var body: some View {
        ZStack {
            // Основная дуга
            geometry.createArcPath()
                .stroke(
                    geometry.task.category.color, 
                    lineWidth: geometry.configuration.arcLineWidth
                )
            
            // Временные метки для drag preview
            if shouldShowTimeMarkersInPreview {
                TaskTimeMarkersForPreview(
                    task: geometry.task,
                    geometry: geometry,
                    timeFormatter: timeFormatter
                )
            }
            
            // Иконка категории
            if shouldShowIcon {
                TaskIcon(
                    task: geometry.task,
                    geometry: geometry,
                    animationManager: animationManager
                )
            }
        }
        .contentShape(.interaction, geometry.createGestureArea())
        .contentShape(.dragPreview, geometry.createDragPreviewArea())
    }
    
    private var shouldShowTimeMarkersInPreview: Bool {
        // Показываем временные метки в drag preview когда:
        // 1. Не аналоговый режим
        // 2. Не режим редактирования
        // 3. Задача достаточно длинная для меток
        !geometry.configuration.isAnalog && 
        !geometry.configuration.isEditingMode &&
        geometry.taskDurationMinutes >= 20
    }
    
    private var shouldShowIcon: Bool {
        // Показываем иконку если не режим редактирования или это не редактируемая задача
        !geometry.configuration.isEditingMode || 
        geometry.taskDurationMinutes < 30
    }
}

// MARK: - Supporting Views
struct TaskTimeMarkersForPreview: View {
    let task: TaskOnRing
    let geometry: TaskArcGeometry
    let timeFormatter: DateFormatter
    
    var body: some View {
        let (startAngle, endAngle) = geometry.angles
        let startTimeText = timeFormatter.string(from: task.startTime)
        let endTimeText = timeFormatter.string(from: task.endTime)
        
        if geometry.taskDurationMinutes >= 40 {
            // Полные маркеры времени
            TaskTimeLabelForPreview(
                text: startTimeText,
                angle: startAngle,
                geometry: geometry,
                isThin: false
            )
            
            TaskTimeLabelForPreview(
                text: endTimeText,
                angle: endAngle,
                geometry: geometry,
                isThin: false
            )
        } else if geometry.taskDurationMinutes >= 20 {
            // Тонкие маркеры для коротких задач
            TaskTimeLabelForPreview(
                text: "",
                angle: startAngle,
                geometry: geometry,
                isThin: true
            )
            
            TaskTimeLabelForPreview(
                text: "",
                angle: endAngle,
                geometry: geometry,
                isThin: true
            )
        }
    }
}

struct TaskTimeLabelForPreview: View {
    let text: String
    let angle: Angle
    let geometry: TaskArcGeometry
    let isThin: Bool
    
    var body: some View {
        let isLeftHalf = geometry.isAngleInLeftHalf(angle)
        let scale = geometry.shortTaskScale * (1.0 + ((geometry.configuration.arcLineWidth - TaskArcConstants.minArcWidth) / (TaskArcConstants.maxArcWidth - TaskArcConstants.minArcWidth)) * 0.5)
        
        ZStack {
            Capsule()
                .fill(geometry.task.category.color)
                .frame(
                    width: isThin ? TaskArcConstants.thinTimeMarkerWidth : 
                           CGFloat(text.count) * TaskArcConstants.timeMarkerCharacterWidth + TaskArcConstants.timeMarkerPadding,
                    height: isThin ? TaskArcConstants.thinTimeMarkerHeight : TaskArcConstants.timeMarkerHeight
                )
            
            if !isThin {
                Text(text)
                    .font(.system(size: TaskArcConstants.timeFontSize))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1)
            }
        }
        .rotationEffect(isLeftHalf ? angle + .degrees(180) : angle)
        .position(geometry.timeMarkerPosition(for: angle, isThin: isThin))
        .scaleEffect(scale)
        .animation(.none, value: angle)
    }
}

struct TaskIcon: View {
    let task: TaskOnRing
    let geometry: TaskArcGeometry
    @ObservedObject var animationManager: TaskArcAnimationManager
    
    var body: some View {
        ZStack {
            // Круглый фон иконки - теперь включен в drag preview
            Circle()
                .fill(task.category.color)
                .frame(width: geometry.iconSize, height: geometry.iconSize)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            
            // Иконка
            Image(systemName: task.category.iconName)
                .font(.system(size: geometry.iconFontSize))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
        }
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