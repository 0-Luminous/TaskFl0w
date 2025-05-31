//
//  TaskArcContentView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI

struct TaskArcContentView: View {
    let task: TaskOnRing
    @ObservedObject var viewModel: ClockViewModel
    let geometry: TaskArcGeometry
    let configuration: TaskArcConfiguration
    @Bindable var animationManager: TaskArcAnimationManager
    let gestureHandler: TaskArcGestureHandler
    let hapticsManager: TaskArcHapticsManager
    let timeFormatter: DateFormatter
    @Binding var isDragging: Bool
    
    var body: some View {
        ZStack {
            // Основная дуга задачи
            TaskArcShape(
                task: task,
                viewModel: viewModel,
                geometry: geometry,
                animationManager: animationManager,
                hapticsManager: hapticsManager,
                isDragging: $isDragging
            )
            
            // Оверлейные элементы (маркеры времени, редактирования)
            TaskOverlayElements(
                task: task,
                viewModel: viewModel,
                isAnalog: configuration.isAnalog,
                center: geometry.center,
                radius: geometry.radius,
                startAngle: geometry.angles.start,
                endAngle: geometry.angles.end,
                arcRadius: geometry.arcRadius,
                arcLineWidth: configuration.arcLineWidth,
                timeTextOffset: TaskArcConstants.timeTextOffset,
                shortTaskScale: geometry.shortTaskScale,
                timeFormatter: timeFormatter,
                analogOffset: geometry.analogOffset,
                tRing: configuration.interpolationFactor,
                lastHourComponent: Binding(
                    get: { gestureHandler.lastHourComponent },
                    set: { gestureHandler.lastHourComponent = $0 }
                ),
                isPressed: animationManager.isPressed,
                adjustTaskStartTimesForOverlap: { task, time in
                    TaskOverlapManager.adjustTaskStartTimesForOverlap(
                        viewModel: viewModel, 
                        currentTask: task, 
                        newStartTime: time
                    )
                },
                adjustTaskEndTimesForOverlap: { task, time in
                    TaskOverlapManager.adjustTaskEndTimesForOverlap(
                        viewModel: viewModel, 
                        currentTask: task, 
                        newEndTime: time
                    )
                },
                triggerHapticFeedback: hapticsManager.triggerSoftFeedback,
                triggerSelectionHapticFeedback: hapticsManager.triggerSelectionFeedback,
                triggerDragHapticFeedback: hapticsManager.triggerDragFeedback,
                handleDragGesture: gestureHandler.handleDragGesture
            )
            .scaleEffect(animationManager.currentScale)
            .opacity(animationManager.appearanceOpacity)
            
            // Иконка категории
            TaskIconView(
                task: task,
                geometry: geometry,
                animationManager: animationManager,
                hapticsManager: hapticsManager
            )
        }
        .scaleEffect(animationManager.appearanceScale)
        .opacity(animationManager.appearanceOpacity)
        .rotationEffect(.degrees(animationManager.appearanceRotation))
    }
} 