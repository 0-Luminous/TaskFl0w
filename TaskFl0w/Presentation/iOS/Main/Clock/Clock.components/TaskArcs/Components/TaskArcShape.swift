//
//  TaskArcShape.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI
import CoreGraphics

struct TaskArcShape: View {
    let geometry: TaskArcGeometry
    let timeFormatter: DateFormatter
    @ObservedObject var animationManager: TaskArcAnimationManager
    @ObservedObject var gestureHandler: TaskArcGestureHandler
    let hapticsManager: TaskArcHapticsManager
    @ObservedObject var viewModel: ClockViewModel
    
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
            
            // Иконка категории с функциональностью перетаскивания всей дуги
            if shouldShowIcon {
                TaskIcon(
                    task: geometry.task,
                    geometry: geometry,
                    animationManager: animationManager,
                    gestureHandler: gestureHandler,
                    hapticsManager: hapticsManager,
                    viewModel: viewModel
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
        // В режиме редактирования скрываем иконку для коротких задач
        return true
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
            // Полные маркеры времени для длинных задач
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
        let scale: CGFloat = 1.0 // Фиксированный масштаб для всех маркеров
        
        ZStack {
            Capsule()
                .fill(geometry.task.category.color)
                .frame(
                    width: isThin ? TaskArcConstants.thinTimeMarkerWidth : 
                           CGFloat(text.count) * TaskArcConstants.timeMarkerCharacterWidth + TaskArcConstants.timeMarkerPadding,
                    height: isThin ? TaskArcConstants.thinTimeMarkerHeight : TaskArcConstants.timeMarkerHeight
                )
                .overlay(
                    // Внутренняя тень
                    Capsule()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.3),
                                    Color.clear,
                                    Color.white.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .overlay(
                    Capsule().stroke(
                        Color(red: 0.6, green: 0.6, blue: 0.6), 
                        lineWidth: 1
                    )
                )
                // Внешняя тень
                .shadow(
                    color: Color.black.opacity(0.25),
                    radius: 2,
                    x: 1,
                    y: 1
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
    @ObservedObject var gestureHandler: TaskArcGestureHandler
    let hapticsManager: TaskArcHapticsManager
    @ObservedObject var viewModel: ClockViewModel
    
    var body: some View {
        ZStack {
            // Круглый фон иконки
            Circle()
                .fill(task.category.color)
                .frame(width: backgroundSize, height: backgroundSize)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            
            // Иконка с индикатором перетаскивания для длинных задач в режиме редактирования
            if shouldShowDragIndicator {
                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .rotationEffect(rotationAngleToCenter)
            } else {
                Image(systemName: task.category.iconName)
                    .font(.system(size: geometry.iconFontSize))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
            }
        }
        .position(currentPosition)
        .scaleEffect(iconScale)
        .opacity(animationManager.appearanceOpacity)
        .rotationEffect(.degrees(animationManager.appearanceRotation * 0.5))
        .animation(.easeInOut(duration: TaskArcConstants.appearanceAnimationDuration), value: geometry.configuration.editingOffset)
        .animation(.none, value: currentPosition)
        .gesture(shouldShowDragIndicator ? createWholeArcDragGesture() : nil)
    }
    
    // MARK: - Computed Properties
    
    private var backgroundSize: CGFloat {
        // Увеличиваем размер фона в режиме редактирования
        shouldShowDragIndicator ? geometry.iconSize * 1.4 : geometry.iconSize
    }
    
    private var shouldShowDragIndicator: Bool {
        viewModel.isEditingMode && 
        task.id == viewModel.editingTask?.id
    }
    
    private var currentPosition: CGPoint {
        // Если идет перетаскивание всей дуги, используем актуальную геометрию
        if gestureHandler.isDraggingWholeArc && shouldShowDragIndicator {
            // Пересчитываем углы на основе актуальных данных задачи
            let currentAngles = RingTimeCalculator.calculateAngles(for: geometry.task)
            let currentMidAngle = RingTimeCalculator.calculateMidAngle(start: currentAngles.start, end: currentAngles.end)
            let midAngleRadians = currentMidAngle.radians
            
            return CGPoint(
                x: geometry.center.x + (geometry.iconRadius ) * cos(midAngleRadians),
                y: geometry.center.y + (geometry.iconRadius ) * sin(midAngleRadians)
            )
        } else if shouldShowDragIndicator {
            // Используем статичную позицию из геометрии с уменьшенным радиусом
            let basePosition = geometry.iconPosition()
            let angle = atan2(basePosition.y - geometry.center.y, basePosition.x - geometry.center.x)
            
            return CGPoint(
                x: geometry.center.x + (geometry.iconRadius ) * cos(angle),
                y: geometry.center.y + (geometry.iconRadius ) * sin(angle)
            )
        } else {
            return geometry.iconPosition()
        }
    }
    
    // Вычисляем угол поворота иконки к центру циферблата
    private var rotationAngleToCenter: Angle {
        let iconPos = currentPosition
        let center = geometry.center
        
        // Вычисляем угол от иконки к центру
        let deltaX = center.x - iconPos.x
        let deltaY = center.y - iconPos.y
        let angleToCenter = atan2(deltaY, deltaX)
        
        return Angle(radians: angleToCenter + .pi/2)
    }
    
    private var iconScale: CGFloat {
        animationManager.appearanceScale * 
        TaskArcConstants.iconScaleMultiplier * 
        (animationManager.isPressed ? TaskArcConstants.pressScale : 1.0)
    }
    
    // MARK: - Gesture Handling
    
    private func createWholeArcDragGesture() -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                // При первом движении инициализируем перетаскивание с правильным смещением
                if !gestureHandler.isDraggingWholeArc {
                    gestureHandler.startWholeArcDrag(
                        at: value.startLocation,
                        center: geometry.center,
                        indicatorPosition: currentPosition
                    )
                    hapticsManager.triggerDragFeedback()
                }
                
                // Обрабатываем перетаскивание с учетом смещения
                gestureHandler.handleWholeArcDrag(value: value, center: geometry.center)
            }
            .onEnded { _ in
                // При завершении перетаскивания проверяем столкновения и корректируем позицию
                gestureHandler.finalizeWholeArcDrag()
                gestureHandler.isDraggingWholeArc = false
                gestureHandler.resetLastHourComponent()
                hapticsManager.triggerSoftFeedback()
            }
    }
} 