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
    @ObservedObject var animationManager: TaskArcAnimationManager
    @ObservedObject var gestureHandler: TaskArcGestureHandler
    let hapticsManager: TaskArcHapticsManager
    let timeFormatter: DateFormatter
    @Binding var isDragging: Bool
    
    var body: some View {
        ZStack {
            // Основная дуга задачи
            TaskArcShape(geometry: geometry)
                .gesture(createTapGesture())
                .gesture(createWholeArcDragGesture())
                .onDrag {
                    handleDragStart()
                    return NSItemProvider(object: task.id.uuidString as NSString)
                } preview: {
                    CategoryDragPreview(task: task)
                }
            
            // Оверлейные элементы (маркеры времени, редактирования)
            TaskOverlayElements(
                task: task,
                viewModel: viewModel,
                geometry: geometry,
                animationManager: animationManager,
                gestureHandler: gestureHandler,
                hapticsManager: hapticsManager,
                timeFormatter: timeFormatter
            )
            
            // Иконка категории
            TaskIconView(
                task: task,
                geometry: geometry,
                animationManager: animationManager
            )
            .gesture(createTapGesture())
        }
        .scaleEffect(animationManager.currentScale)
        .opacity(animationManager.appearanceOpacity)
        .rotationEffect(.degrees(animationManager.appearanceRotation))
    }
    
    // MARK: - Private Methods
    
    private func createTapGesture() -> some Gesture {
        TapGesture()
            .onEnded {
                hapticsManager.triggerSoftFeedback()
                animationManager.triggerPressAnimation()
                
                withAnimation(.easeInOut(duration: 0.3).delay(0.1)) {
                    toggleEditingMode()
                }
            }
    }
    
    private func toggleEditingMode() {
        if viewModel.isEditingMode, viewModel.editingTask?.id == task.id {
            viewModel.isEditingMode = false
            viewModel.editingTask = nil
        } else {
            viewModel.isEditingMode = true
            viewModel.editingTask = task
        }
    }
    
    private func handleDragStart() -> NSItemProvider {
        if !viewModel.isEditingMode && viewModel.editingTask == nil && !isDragging {
            viewModel.startDragging(task)
            isDragging = true
            hapticsManager.triggerHardFeedback()
            return NSItemProvider(object: task.id.uuidString as NSString)
        }
        return NSItemProvider()
    }
    
    private func createWholeArcDragGesture() -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                if viewModel.isEditingMode && viewModel.editingTask?.id == task.id {
                    gestureHandler.isDraggingWholeArc = true
                    gestureHandler.handleWholeArcDrag(value: value, center: geometry.center)
                }
            }
            .onEnded { _ in
                gestureHandler.isDraggingWholeArc = false
                gestureHandler.resetLastHourComponent()
                hapticsManager.triggerSoftFeedback()
            }
    }
} 