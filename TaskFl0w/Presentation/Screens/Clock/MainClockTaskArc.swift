//
//  MainClockTaskArc.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct MainClockTaskArc: View {
    let task: Task
    @ObservedObject var viewModel: ClockViewModel
    
    var body: some View {
        GeometryReader { geometry in
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
                    TapGesture()
                        .onEnded {
                            withAnimation {
                                if viewModel.isEditingMode, viewModel.editingTask?.id == task.id {
                                    viewModel.isEditingMode = false
                                    viewModel.editingTask = nil
                                } else {
                                    viewModel.isEditingMode = true
                                    viewModel.editingTask = task
                                }
                            }
                        }
                )
                .simultaneousGesture(
                    TapGesture(count: 2)
                        .onEnded {
                            if !viewModel.isEditingMode {
                                viewModel.selectedTask = task
                                viewModel.showingTaskDetail = true
                            }
                        }
                )
                
                // Если текущая задача в режиме редактирования — показываем маркеры
                if viewModel.isEditingMode && task.id == viewModel.editingTask?.id {
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
                                    viewModel.isDraggingStart = true
                                    let newTime = timeForLocation(value.location, center: center)
                                    viewModel.previewTime = newTime
                                    viewModel.taskManagement.updateTaskStartTimeKeepingEnd(task, newStartTime: newTime)
                                }
                                .onEnded { _ in
                                    viewModel.isDraggingStart = false
                                    viewModel.previewTime = nil
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
                                    viewModel.isDraggingEnd = true
                                    let newTime = timeForLocation(value.location, center: center)
                                    viewModel.previewTime = newTime
                                    viewModel.taskManagement.updateTaskDuration(task, newEndTime: newTime)
                                }
                                .onEnded { _ in
                                    viewModel.isDraggingEnd = false
                                    viewModel.previewTime = nil
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

