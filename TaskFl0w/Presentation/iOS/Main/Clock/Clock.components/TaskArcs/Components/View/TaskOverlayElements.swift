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
            
            // Метки времени
            if shouldShowTimeMarkers {
                TaskTimeMarkers(
                    task: task,
                    geometry: geometry,
                    timeFormatter: timeFormatter
                )
            }
            
            if shouldShowWholeArcDragHandle {
                WholeArcDragIndicator(
                    midAngle: geometry.midAngle,
                    geometry: geometry,
                    gestureHandler: gestureHandler,
                    hapticsManager: hapticsManager,
                    viewModel: viewModel
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    private var shouldShowDragHandles: Bool {
        viewModel.isEditingMode && task.id == viewModel.editingTask?.id
    }
    
    private var shouldShowTimeMarkers: Bool {
        !geometry.configuration.isAnalog && 
        !geometry.configuration.isEditingMode && 
        (!geometry.configuration.showTimeOnlyForActiveTask || geometry.isActiveTask)
    }
    
    private var shouldShowWholeArcDragHandle: Bool {
        viewModel.isEditingMode && task.id == viewModel.editingTask?.id && geometry.taskDurationMinutes >= 30
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

struct TaskTimeMarkers: View {
    let task: TaskOnRing
    let geometry: TaskArcGeometry
    let timeFormatter: DateFormatter
    
    var body: some View {
        let (startAngle, endAngle) = geometry.angles
        let startTimeText = timeFormatter.string(from: task.startTime)
        let endTimeText = timeFormatter.string(from: task.endTime)
        
        if geometry.taskDurationMinutes >= 40 {
            // Полные маркеры времени
            TaskTimeLabel(
                text: startTimeText,
                angle: startAngle,
                geometry: geometry,
                isThin: false
            )
            
            TaskTimeLabel(
                text: endTimeText,
                angle: endAngle,
                geometry: geometry,
                isThin: false
            )
        } else if geometry.taskDurationMinutes >= 20 {
            // Тонкие маркеры для коротких задач
            TaskTimeLabel(
                text: "",
                angle: startAngle,
                geometry: geometry,
                isThin: true
            )
            
            TaskTimeLabel(
                text: "",
                angle: endAngle,
                geometry: geometry,
                isThin: true
            )
        }
    }
}

struct TaskTimeLabel: View {
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
    }
}

struct WholeArcDragIndicator: View {
    let midAngle: Angle
    let geometry: TaskArcGeometry
    @ObservedObject var gestureHandler: TaskArcGestureHandler
    let hapticsManager: TaskArcHapticsManager
    @ObservedObject var viewModel: ClockViewModel
    
    var body: some View {
        Image(systemName: "move.3d")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .background(
                Circle()
                    .fill(geometry.task.category.color)
                    .frame(width: 32, height: 32)
            )
            .position(geometry.iconPosition())
            .gesture(createWholeArcDragGesture())
    }
    
    private func createWholeArcDragGesture() -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                gestureHandler.isDraggingWholeArc = true
                gestureHandler.handleWholeArcDrag(value: value, center: geometry.center)
                hapticsManager.triggerDragFeedback()
            }
            .onEnded { _ in
                gestureHandler.isDraggingWholeArc = false
                gestureHandler.resetLastHourComponent()
                hapticsManager.triggerSoftFeedback()
            }
    }
}