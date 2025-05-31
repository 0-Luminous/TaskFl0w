//
//  TaskArcShape.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI

struct TaskArcShape: View {
    let task: TaskOnRing
    @ObservedObject var viewModel: ClockViewModel
    let geometry: TaskArcGeometry
    @Bindable var animationManager: TaskArcAnimationManager
    let hapticsManager: TaskArcHapticsManager
    @Binding var isDragging: Bool
    
    var body: some View {
        geometry.createArcPath()
            .stroke(task.category.color, lineWidth: geometry.configuration.arcLineWidth)
            .contentShape(.interaction, geometry.createGestureArea())
            .onTapGesture {
                handleTap()
            }
            .onDrag {
                return handleDragStart()
            } preview: {
                CategoryDragPreview(task: task)
            }
    }
    
    private func handleTap() {
        hapticsManager.triggerSoftFeedback()
        animationManager.triggerPressAnimation()
        
        withAnimation(.easeInOut(duration: 0.3).delay(0.1)) {
            if viewModel.isEditingMode, viewModel.editingTask?.id == task.id {
                viewModel.isEditingMode = false
                viewModel.editingTask = nil
            } else {
                viewModel.isEditingMode = true
                viewModel.editingTask = task
            }
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
} 