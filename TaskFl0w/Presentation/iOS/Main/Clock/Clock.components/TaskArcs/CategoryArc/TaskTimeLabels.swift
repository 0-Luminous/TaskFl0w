//
//  TaskTimeLabels.swift
//  TaskFl0w
//
//  Created by Yan on 29/5/25.
//
import SwiftUI

struct TaskTimeLabels: View {
    let task: TaskOnRing
    let isAnalog: Bool
    let viewModel: ClockViewModel
    let startAngle: Angle
    let endAngle: Angle
    let center: CGPoint
    let arcRadius: CGFloat
    let timeTextOffset: CGFloat
    let shortTaskScale: CGFloat
    let timeFormatter: DateFormatter
    
    // Добавим вычисление длительности задачи в минутах
    private var taskDurationMinutes: Double {
        return task.duration / 60
    }
    
    // Добавляем доступ к толщине дуги
    var arcLineWidth: CGFloat {
        return isAnalog ? viewModel.outerRingLineWidth : viewModel.taskArcLineWidth
    }
    
    // Вынесено в отдельные методы для улучшения читаемости и оптимизации
    private func isAngleInLeftHalf(_ angle: Angle) -> Bool {
        let degrees = (angle.degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        return degrees > 90 && degrees < 270
    }
    
    // Проверка активности задачи
    private var isActiveTask: Bool {
        let now = Date()
        return (task.startTime <= now && task.endTime > now) || viewModel.editingTask?.id == task.id
    }
    
    // Проверка условий для отображения времени
    private var shouldShowTime: Bool {
        !isAnalog && 
        !(viewModel.isEditingMode && task.id == viewModel.editingTask?.id) && 
        (!viewModel.showTimeOnlyForActiveTask || (viewModel.showTimeOnlyForActiveTask && isActiveTask))
    }
    
    // Кэшируем вычисления для отображения времени
    private var timeLabels: (start: TimeLabel, end: TimeLabel)? {
        guard shouldShowTime else { return nil }
        
        let startTimeText = timeFormatter.string(from: task.startTime)
        let endTimeText = timeFormatter.string(from: task.endTime)
        let isStartInLeftHalf = isAngleInLeftHalf(startAngle)
        let isEndInLeftHalf = isAngleInLeftHalf(endAngle)
        let arcWidthScale = calculateArcWidthScale()
        
        if taskDurationMinutes >= 40 {
            return (
                createTimeLabel(text: startTimeText, angle: startAngle, isLeftHalf: isStartInLeftHalf, isThin: false),
                createTimeLabel(text: endTimeText, angle: endAngle, isLeftHalf: isEndInLeftHalf, isThin: false)
            )
        } else {
            return (
                createTimeLabel(text: "", angle: startAngle, isLeftHalf: isStartInLeftHalf, isThin: true),
                createTimeLabel(text: "", angle: endAngle, isLeftHalf: isEndInLeftHalf, isThin: true)
            )
        }
    }
    
    private func calculateArcWidthScale() -> CGFloat {
        let minArcWidth: CGFloat = 20
        let maxArcWidth: CGFloat = 32
        return 1.0 + ((arcLineWidth - minArcWidth) / (maxArcWidth - minArcWidth)) * 0.5
    }
    
    private func createTimeLabel(text: String, angle: Angle, isLeftHalf: Bool, isThin: Bool) -> TimeLabel {
        TimeLabel(
            timeText: text,
            angle: angle,
            isLeftHalf: isLeftHalf,
            color: task.category.color,
            center: center,
            radius: arcRadius,
            offset: timeTextOffset,
            scale: shortTaskScale * calculateArcWidthScale(),
            isThin: isThin,
            showText: !isThin
        )
    }
    
    var body: some View {
        if let (startLabel, endLabel) = timeLabels {
            startLabel
            endLabel
        }
    }
}

// Модифицируем структуру TimeLabel, убирая зависимость от Environment
struct TimeLabel: View {
    let timeText: String
    let angle: Angle
    let isLeftHalf: Bool
    let color: Color
    let center: CGPoint
    let radius: CGFloat
    let offset: CGFloat
    let scale: CGFloat
    let isThin: Bool
    let showText: Bool

    var body: some View {
        ZStack {
            Capsule()
                .fill(color)
                .frame(
                    width: isThin ? 35 : CGFloat(timeText.count) * 6 + 6,
                    height: isThin ? 8 : 16
                )
            if showText {
                Text(timeText)
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1)
            }
        }
        .rotationEffect(isLeftHalf ? angle + .degrees(180) : angle)
        .position(
            x: center.x + (radius + offset) * cos(angle.radians),
            y: center.y + (radius + offset) * sin(angle.radians)
        )
    }
}

