//
//  MainClockTaskArc.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct MainClockTaskArc: View {
    let task: Task
    let geometry: GeometryProxy
    @ObservedObject var viewModel: ClockViewModel
    
    @Binding var selectedTask: Task?
    @Binding var showingTaskDetail: Bool
    @Binding var isEditingMode: Bool
    @Binding var editingTask: Task?
    @Binding var isDraggingStart: Bool
    @Binding var isDraggingEnd: Bool
    @Binding var previewTime: Date?
    
    var body: some View {
        let center = CGPoint(x: geometry.size.width / 2,
                             y: geometry.size.height / 2)
        let radius = min(geometry.size.width, geometry.size.height) / 2
        let (startAngle, endAngle) = calculateAngles()
        
        ZStack {
            // Дуга задачи
            Path { path in
                path.addArc(center: center,
                            radius: radius + 10,
                            startAngle: startAngle,
                            endAngle: endAngle,
                            clockwise: false)
            }
            .stroke(task.category.color, lineWidth: 20)
            .gesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        withAnimation {
                            // Если уже редактируем именно эту задачу — выключаем
                            if isEditingMode, editingTask?.id == task.id {
                                isEditingMode = false
                                editingTask = nil
                            } else {
                                // Иначе включаем режим редактирования
                                isEditingMode = true
                                editingTask = task
                            }
                        }
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        if !isEditingMode {
                            selectedTask = task
                            showingTaskDetail = true
                        }
                    }
            )
            
            // Если текущая задача в режиме редактирования — показываем маркеры
            if isEditingMode && task.id == editingTask?.id {
                // Маркер начала
                Circle()
                    .fill(task.category.color)
                    .frame(width: 24, height: 24)
                    .position(
                        x: center.x + (radius + 10) * CGFloat(cos(startAngle.radians)),
                        y: center.y + (radius + 10) * CGFloat(sin(startAngle.radians))
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDraggingStart = true
                                let newTime = timeForLocation(value.location, center: center)
                                previewTime = newTime
                                viewModel.updateTaskStartTimeKeepingEnd(task, newStartTime: newTime)
                            }
                            .onEnded { _ in
                                isDraggingStart = false
                                previewTime = nil
                            }
                    )
                
                // Маркер конца
                Circle()
                    .fill(task.category.color)
                    .frame(width: 24, height: 24)
                    .position(
                        x: center.x + (radius + 10) * CGFloat(cos(endAngle.radians)),
                        y: center.y + (radius + 10) * CGFloat(sin(endAngle.radians))
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDraggingEnd = true
                                let newTime = timeForLocation(value.location, center: center)
                                previewTime = newTime
                                viewModel.updateTaskDuration(task, newEndTime: newTime)
                            }
                            .onEnded { _ in
                                isDraggingEnd = false
                                previewTime = nil
                            }
                    )
            }
            
            // Иконка категории на середине дуги
            let midAngle = calculateMidAngle(start: startAngle, end: endAngle)
            Image(systemName: task.category.iconName)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .background(
                    Circle()
                        .fill(task.category.color)
                        .frame(width: 20, height: 20)
                )
                .position(
                    x: center.x + (radius + 20) * CGFloat(cos(midAngle.radians)),
                    y: center.y + (radius + 20) * CGFloat(sin(midAngle.radians))
                )
        }
    }
    
    // MARK: - Подсчёт углов
    
    private func calculateAngles() -> (start: Angle, end: Angle) {
        let calendar = Calendar.current
        
        let startHour = CGFloat(calendar.component(.hour, from: task.startTime))
        let startMinute = CGFloat(calendar.component(.minute, from: task.startTime))
        let endTime = task.startTime.addingTimeInterval(task.duration)
        let endHour = CGFloat(calendar.component(.hour, from: endTime))
        let endMinute = CGFloat(calendar.component(.minute, from: endTime))
        
        let startMinutes = startHour * 60 + startMinute
        var endMinutes = endHour * 60 + endMinute
        
        // Если задача идёт за полночь
        if endMinutes < startMinutes {
            endMinutes += 24 * 60
        }
        
        // 24 часа = 1440 минут => 360 градусов
        let startAngle = Angle(degrees: 90 + Double(startMinutes) / 4)
        let endAngle = Angle(degrees: 90 + Double(endMinutes) / 4)
        
        return (startAngle, endAngle)
    }
    
    private func calculateMidAngle(start: Angle, end: Angle) -> Angle {
        var midDegrees = (start.degrees + end.degrees) / 2
        // Если дуга "переходит" через 360
        if end.degrees < start.degrees {
            midDegrees = (start.degrees + (end.degrees + 360)) / 2
            if midDegrees >= 360 {
                midDegrees -= 360
            }
        }
        return Angle(degrees: midDegrees)
    }
    
    // MARK: - Помощник для DragGesture
    
    private func timeForLocation(_ location: CGPoint, center: CGPoint) -> Date {
        let vector = CGVector(dx: location.x - center.x, dy: location.y - center.y)
        let angle = atan2(vector.dy, vector.dx)
        var degrees = angle * 180 / .pi
        degrees = (degrees - 90 + 360).truncatingRemainder(dividingBy: 360)
        
        let hours = degrees / 15
        let hourComponent = Int(hours)
        let minuteComponent = Int((hours - Double(hourComponent)) * 60)
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: task.startTime)
        components.hour = hourComponent
        components.minute = minuteComponent
        
        return Calendar.current.date(from: components) ?? task.startTime
    }
}

