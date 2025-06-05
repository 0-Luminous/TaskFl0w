//
//  TaskOverlayElements.swift
//  TaskFl0w
//
//  Created by Yan on 30/5/25.
//
import SwiftUI 

struct TaskOverlayElements: View {
    let task: TaskOnRing
    @ObservedObject var viewModel: ClockViewModel
    let geometry: TaskArcGeometry
    @ObservedObject var animationManager: TaskArcAnimationManager
    @ObservedObject var gestureHandler: TaskArcGestureHandler
    let hapticsManager: TaskArcHapticsManager
    let timeFormatter: DateFormatter
    
    var body: some View {
        ZStack {
            // Маркеры редактирования
            if shouldShowDragHandles {
                TaskDragHandle(
                    angle: geometry.angles.start,
                    geometry: geometry,
                    gestureHandler: gestureHandler,
                    hapticsManager: hapticsManager,
                    viewModel: viewModel,
                    isDraggingStart: true
                )
                
                TaskDragHandle(
                    angle: geometry.angles.end,
                    geometry: geometry,
                    gestureHandler: gestureHandler,
                    hapticsManager: hapticsManager,
                    viewModel: viewModel,
                    isDraggingStart: false
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    private var shouldShowDragHandles: Bool {
        viewModel.isEditingMode && task.id == viewModel.editingTask?.id
    }
}

// MARK: - Supporting Views
struct TaskDragHandle: View {
    let angle: Angle
    let geometry: TaskArcGeometry
    @ObservedObject var gestureHandler: TaskArcGestureHandler
    let hapticsManager: TaskArcHapticsManager
    @ObservedObject var viewModel: ClockViewModel
    let isDraggingStart: Bool
    
    var body: some View {
        let (handleWidth, handleHeight) = geometry.handleSize
        let (touchWidth, touchHeight) = geometry.touchAreaSize
        let isLeftHalf = geometry.isAngleInLeftHalf(angle)
        
        Capsule()
            .fill(geometry.task.category.color)
            .frame(width: handleWidth, height: handleHeight)
            .overlay(
                Capsule().stroke(
                    Color.gray, 
                    lineWidth: TaskArcConstants.handleStrokeWidth * geometry.shortTaskScale
                )
            )
            .contentShape(
                Capsule().size(width: touchWidth, height: touchHeight)
            )
            .rotationEffect(isLeftHalf ? angle + .degrees(180) : angle)
            .position(geometry.handlePosition(for: angle))
            .animation(.none, value: angle)
            .gesture(createDragGesture())
    }
    
    private func createDragGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                handleDragStart()
                handleDragChange(value)
            }
            .onEnded { _ in
                handleDragEnd()
            }
    }
    
    private func handleDragStart() {
        if isDraggingStart {
            viewModel.isDraggingStart = true
        } else {
            viewModel.isDraggingEnd = true
        }
        
        if gestureHandler.lastHourComponent == -1 {
            hapticsManager.triggerDragFeedback()
        }
    }
    
    private func handleDragChange(_ value: DragGesture.Value) {
        gestureHandler.handleDragGesture(
            value: value,
            center: geometry.center,
            isDraggingStart: isDraggingStart
        )
    }
    
    private func handleDragEnd() {
        updateEditingTask()
        resetDragState()
        gestureHandler.resetLastHourComponent()
        hapticsManager.triggerSoftFeedback()
    }
    
    private func updateEditingTask() {
        if let updatedTask = viewModel.editingTask,
           let actualTask = viewModel.tasks.first(where: { $0.id == updatedTask.id }) {
            viewModel.editingTask = actualTask
        }
    }
    
    private func resetDragState() {
        if isDraggingStart {
            viewModel.isDraggingStart = false
        } else {
            viewModel.isDraggingEnd = false
        }
        viewModel.previewTime = nil
    }
}