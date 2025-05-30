//
//  TaskOverlayElements.swift
//  TaskFl0w
//
//  Created by Yan on 30/5/25.
//
import SwiftUI 

// MARK: - Объединенная структура для маркеров и меток времени
struct TaskOverlayElements: View {
    let task: TaskOnRing
    @ObservedObject var viewModel: ClockViewModel
    let isAnalog: Bool
    let center: CGPoint
    let radius: CGFloat
    let startAngle: Angle
    let endAngle: Angle
    let arcRadius: CGFloat
    let arcLineWidth: CGFloat
    let timeTextOffset: CGFloat
    let shortTaskScale: CGFloat
    let timeFormatter: DateFormatter
    let analogOffset: CGFloat
    let tRing: CGFloat
    @Binding var lastHourComponent: Int
    
    // Колбэки для обработки действий
    let adjustTaskStartTimesForOverlap: (TaskOnRing, Date) -> Void
    let adjustTaskEndTimesForOverlap: (TaskOnRing, Date) -> Void
    let triggerHapticFeedback: () -> Void
    let triggerSelectionHapticFeedback: () -> Void
    let triggerDragHapticFeedback: () -> Void
    let handleDragGesture: (DragGesture.Value, CGPoint, Bool) -> Void
    
    // MARK: - Константы
    private let minOuterRingWidth: CGFloat = 20
    private let maxOuterRingWidth: CGFloat = 38
    private let minHandleSize: CGFloat = 20
    private let maxHandleSize: CGFloat = 30
    private let minArcWidth: CGFloat = 20
    private let maxArcWidth: CGFloat = 32
    
    // MARK: - Вычисляемые свойства
    private var taskDurationMinutes: Double {
        return task.duration / 60
    }
    
    private var isActiveTask: Bool {
        let now = Date()
        return (task.startTime <= now && task.endTime > now) || viewModel.editingTask?.id == task.id
    }
    
    private var shouldShowTime: Bool {
        !isAnalog && 
        !(viewModel.isEditingMode && task.id == viewModel.editingTask?.id) && 
        (!viewModel.showTimeOnlyForActiveTask || (viewModel.showTimeOnlyForActiveTask && isActiveTask))
    }
    
    private var shouldShowDragHandles: Bool {
        viewModel.isEditingMode && task.id == viewModel.editingTask?.id
    }
    
    // MARK: - Вспомогательные методы
    private func isAngleInLeftHalf(_ angle: Angle) -> Bool {
        let degrees = (angle.degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        return degrees > 90 && degrees < 270
    }
    
    private func calculateArcWidthScale() -> CGFloat {
        return 1.0 + ((arcLineWidth - minArcWidth) / (maxArcWidth - minArcWidth)) * 0.5
    }
    
    private func calculateHandleSize() -> (width: CGFloat, height: CGFloat) {
        let t = (viewModel.outerRingLineWidth - minOuterRingWidth) / (maxOuterRingWidth - minOuterRingWidth)
        let baseHandleSize: CGFloat = isAnalog
            ? minHandleSize + (maxHandleSize - minHandleSize) * t
            : minHandleSize
        let baseHandleWidth: CGFloat = baseHandleSize
        let handleHeight: CGFloat = baseHandleSize * pow(shortTaskScale, 2)
        
        return (width: baseHandleWidth, height: handleHeight)
    }
    
    // MARK: - Создание элементов
    @ViewBuilder
    private func createTimeLabel(text: String, angle: Angle, isLeftHalf: Bool, isThin: Bool) -> some View {
        let scale = shortTaskScale * calculateArcWidthScale()
        
        ZStack {
            Capsule()
                .fill(task.category.color)
                .frame(
                    width: isThin ? 25 : CGFloat(text.count) * 6 + 6,
                    height: isThin ? 4 : 16
                )
            if !isThin {
                Text(text)
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1)
            }
        }
        .rotationEffect(isLeftHalf ? angle + .degrees(180) : angle)
        .position(
            x: center.x + (isThin ? arcRadius - 3 : arcRadius + timeTextOffset) * cos(angle.radians),
            y: center.y + (isThin ? arcRadius - 3 : arcRadius + timeTextOffset) * sin(angle.radians)
        )
    }
    
    @ViewBuilder
    private func createDragHandle(
        angle: Angle,
        isDraggingStart: Bool
    ) -> some View {
        let (handleWidth, handleHeight) = calculateHandleSize()
        let touchAreaWidth: CGFloat = max(handleWidth, 35)
        let touchAreaHeight: CGFloat = shortTaskScale > 0.8 ? max(handleHeight, 44) : handleHeight * 1.5
        let isLeftHalf = isAngleInLeftHalf(angle)
        
        Capsule()
            .fill(task.category.color)
            .frame(width: handleWidth, height: handleHeight)
            .overlay(Capsule().stroke(Color.gray, lineWidth: 2 * shortTaskScale))
            .contentShape(Capsule()
                .size(width: touchAreaWidth, height: touchAreaHeight))
            .rotationEffect(isLeftHalf ? angle + .degrees(180) : angle)
            .position(
                x: center.x + arcRadius * cos(angle.radians),
                y: center.y + arcRadius * sin(angle.radians)
            )
            .animation(.none, value: angle)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if isDraggingStart {
                            viewModel.isDraggingStart = true
                        } else {
                            viewModel.isDraggingEnd = true
                        }
                        
                        if lastHourComponent == -1 {
                            triggerDragHapticFeedback()
                        }
                        
                        handleDragGesture(value, center, isDraggingStart)
                    }
                    .onEnded { _ in
                        if let updatedTask = viewModel.editingTask,
                            let actualTask = viewModel.tasks.first(where: {
                                $0.id == updatedTask.id
                            })
                        {
                            viewModel.editingTask = actualTask
                        }

                        if isDraggingStart {
                            viewModel.isDraggingStart = false
                        } else {
                            viewModel.isDraggingEnd = false
                        }
                        viewModel.previewTime = nil
                        lastHourComponent = -1
                        triggerHapticFeedback()
                    }
            )
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Маркеры редактирования
            if shouldShowDragHandles {
                createDragHandle(angle: startAngle, isDraggingStart: true)
                createDragHandle(angle: endAngle, isDraggingStart: false)
            }
            
            // Метки времени
            if shouldShowTime {
                let startTimeText = timeFormatter.string(from: task.startTime)
                let endTimeText = timeFormatter.string(from: task.endTime)
                let isStartInLeftHalf = isAngleInLeftHalf(startAngle)
                let isEndInLeftHalf = isAngleInLeftHalf(endAngle)
                
                if taskDurationMinutes >= 40 {
                    createTimeLabel(text: startTimeText, angle: startAngle, isLeftHalf: isStartInLeftHalf, isThin: false)
                    createTimeLabel(text: endTimeText, angle: endAngle, isLeftHalf: isEndInLeftHalf, isThin: false)
                } else {
                    createTimeLabel(text: "", angle: startAngle, isLeftHalf: isStartInLeftHalf, isThin: true)
                    createTimeLabel(text: "", angle: endAngle, isLeftHalf: isEndInLeftHalf, isThin: true)
                }
            }
        }
    }
}