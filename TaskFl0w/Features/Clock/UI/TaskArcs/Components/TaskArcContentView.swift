//
//  TaskArcContentView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI
import CoreGraphics

struct TaskArcContentView: View {
    let task: TaskOnRing
    @ObservedObject var viewModel: ClockViewModel
    let geometry: TaskArcGeometry
    let configuration: TaskArcConfiguration
    @ObservedObject var animationManager: TaskArcAnimationManager
    @ObservedObject var gestureHandler: TaskArcGestureHandler
    let hapticsManager: HapticsManager
    let timeFormatter: DateFormatter
    @Binding var isDragging: Bool
    
    var body: some View {
        ZStack {
            TaskArcShape(
                geometry: geometry, 
                timeFormatter: timeFormatter,
                hapticsManager: hapticsManager,
                animationManager: animationManager,
                gestureHandler: gestureHandler,
                viewModel: viewModel
            )
                .gesture(createTapGesture())
                .onDrag {
                    return handleDragStart()
                } preview: {
                    CategoryDragPreview(task: task)
                }
            
            TaskOverlayElements(
                task: task,
                viewModel: viewModel,
                geometry: geometry,
                animationManager: animationManager,
                gestureHandler: gestureHandler,
                hapticsManager: hapticsManager,
                timeFormatter: timeFormatter
            )
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
            hapticsManager.triggerHeavyFeedback()
            return NSItemProvider(object: task.id.uuidString as NSString)
        }
        return NSItemProvider()
    }
}

// MARK: - Supporting Views
struct WholeArcDragIndicator: View {
    let midAngle: Angle
    let geometry: TaskArcGeometry
    @ObservedObject var gestureHandler: TaskArcGestureHandler
    let hapticsManager: HapticsManager
    @ObservedObject var viewModel: ClockViewModel
    
    var body: some View {
        Image(systemName: "arrow.left.and.right")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .rotationEffect(rotationAngleToCenter)
            .background(
                Circle()
                    .fill(geometry.task.category.color)
                    .stroke(.gray, lineWidth: 2)
                    .frame(width: 25, height: 25)
            )
            .contentShape(Circle().size(width: 35, height: 35))
            .position(currentPosition)
            .animation(.none, value: currentPosition)
            .gesture(createWholeArcDragGesture())
    }
    
    private var rotationAngleToCenter: Angle {
        let iconPos = currentPosition
        let center = geometry.center
        
        let deltaX = center.x - iconPos.x
        let deltaY = center.y - iconPos.y
        let angleToCenter = atan2(deltaY, deltaX)
        
        return Angle(radians: angleToCenter + .pi/2)
    }
    
    private var currentPosition: CGPoint {
        if gestureHandler.isDraggingWholeArc {
            let currentAngles = RingTimeCalculator.calculateAngles(for: geometry.task)
            let currentMidAngle = RingTimeCalculator.calculateMidAngle(start: currentAngles.start, end: currentAngles.end)
            let midAngleRadians = currentMidAngle.radians
            
            return CGPoint(
                x: geometry.center.x + (geometry.iconRadius + 10) * cos(midAngleRadians),
                y: geometry.center.y + (geometry.iconRadius + 10) * sin(midAngleRadians)
            )
        } else {
            let basePosition = geometry.iconPosition()
            let angle = atan2(basePosition.y - geometry.center.y, basePosition.x - geometry.center.x)
            
            return CGPoint(
                x: geometry.center.x + (geometry.iconRadius + 10) * cos(angle),
                y: geometry.center.y + (geometry.iconRadius + 10) * sin(angle)
            )
        }
    }
    
    private func createWholeArcDragGesture() -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                if !gestureHandler.isDraggingWholeArc {
                    gestureHandler.startWholeArcDrag(
                        at: value.startLocation,
                        center: geometry.center,
                        indicatorPosition: currentPosition
                    )
                    hapticsManager.triggerLightFeedback()
                }
                
                gestureHandler.handleWholeArcDrag(value: value, center: geometry.center)
            }
            .onEnded { _ in
                gestureHandler.finalizeWholeArcDrag()
                gestureHandler.isDraggingWholeArc = false
                gestureHandler.resetLastHourComponent()
                hapticsManager.triggerSoftFeedback()
            }
    }
} 
