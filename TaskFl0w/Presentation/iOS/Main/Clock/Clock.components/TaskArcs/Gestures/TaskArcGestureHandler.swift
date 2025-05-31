//
//  TaskArcGestureHandler.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI

class TaskArcGestureHandler: ObservableObject {
    private let viewModel: ClockViewModel
    private let task: TaskOnRing
    private let hapticsManager = TaskArcHapticsManager()
    
    @Published var lastHourComponent: Int = -1
    
    init(viewModel: ClockViewModel, task: TaskOnRing) {
        self.viewModel = viewModel
        self.task = task
    }
    
    func handleDragGesture(value: DragGesture.Value, center: CGPoint, isDraggingStart: Bool) {
        let vector = CGVector(dx: value.location.x - center.x, dy: value.location.y - center.y)
        let angle = atan2(vector.dy, vector.dx)
        let degrees = (angle * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
        let adjustedDegrees = (degrees - 270 - viewModel.zeroPosition + 360).truncatingRemainder(dividingBy: 360)
        
        let hours = adjustedDegrees / 15
        let hourComponent = Int(hours)
        let minuteComponent = Int((hours - Double(hourComponent)) * 60)
        
        handleHourChange(hourComponent)
        handleMinuteChange(minuteComponent)
        updateTaskTime(hourComponent: hourComponent, minuteComponent: minuteComponent, isDraggingStart: isDraggingStart)
    }
    
    private func handleHourChange(_ hourComponent: Int) {
        if hourComponent != lastHourComponent {
            if lastHourComponent != -1 {
                hapticsManager.triggerSelectionFeedback()
            }
            lastHourComponent = hourComponent
        }
    }
    
    private func handleMinuteChange(_ minuteComponent: Int) {
        let currentMinuteBucket = minuteComponent / 5
        if currentMinuteBucket != (minuteComponent - 1) / 5 && lastHourComponent != -1 {
            hapticsManager.triggerDragFeedback()
        }
    }
    
    private func updateTaskTime(hourComponent: Int, minuteComponent: Int, isDraggingStart: Bool) {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: viewModel.selectedDate)
        components.hour = hourComponent
        components.minute = minuteComponent
        components.timeZone = TimeZone.current
        
        guard let newTime = Calendar.current.date(from: components) else { return }
        
        if isDraggingStart {
            handleStartTimeUpdate(newTime, hourComponent: hourComponent, minuteComponent: minuteComponent)
        } else {
            handleEndTimeUpdate(newTime, hourComponent: hourComponent, minuteComponent: minuteComponent)
        }
    }
    
    private func handleStartTimeUpdate(_ newTime: Date, hourComponent: Int, minuteComponent: Int) {
        guard hourComponent != 0 || minuteComponent != 0 else { return }
        guard task.endTime.timeIntervalSince(newTime) >= TaskArcConstants.minimumDuration else { return }
        
        viewModel.previewTime = newTime
        TaskOverlapManager.adjustTaskStartTimesForOverlap(viewModel: viewModel, currentTask: task, newStartTime: newTime)
    }
    
    private func handleEndTimeUpdate(_ newTime: Date, hourComponent: Int, minuteComponent: Int) {
        guard hourComponent != 0 || minuteComponent != 0 else { return }
        guard newTime.timeIntervalSince(task.startTime) >= TaskArcConstants.minimumDuration else { return }
        
        viewModel.previewTime = newTime
        TaskOverlapManager.adjustTaskEndTimesForOverlap(viewModel: viewModel, currentTask: task, newEndTime: newTime)
    }
    
    func resetLastHourComponent() {
        lastHourComponent = -1
    }
} 