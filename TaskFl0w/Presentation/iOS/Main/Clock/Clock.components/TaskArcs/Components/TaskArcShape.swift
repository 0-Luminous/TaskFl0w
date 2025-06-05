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