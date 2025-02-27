//
//  MainClockFaceView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct GlobleClockFaceViewIpad: View {
    let currentDate: Date
    let tasks: [Task]
    @ObservedObject var viewModel: ClockViewModel
    
    @Binding var draggedCategory: TaskCategoryModel?
    let clockFaceColor: Color
    let zeroPosition: Double
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("clockStyle") private var clockStyle: ClockStyle = .classic
    @AppStorage("markersOffset") private var markersOffset: Double = 40.0
    
    // Локальные состояния убраны и перенесены в ViewModel
    // Используем состояния из ViewModel через viewModel
    
    var body: some View {
        ZStack {
            Circle()
                .fill(clockFaceColor)
                .stroke(Color.gray, lineWidth: 2)
            
            // Маркеры часов (24 шт.)
            ForEach(0..<24) { hour in
                let angle = Double(hour) * (360.0 / 24.0) + zeroPosition
                ClockMarkerForIpad(hour: hour, style: clockStyle.markerStyle)
                    .rotationEffect(.degrees(angle))
                    .frame(width: UIScreen.main.bounds.width * 0.35, height: UIScreen.main.bounds.width * 0.35)
            }
            
            TaskArcsViewIpad(
                tasks: tasksForSelectedDate,
                viewModel: viewModel
            )
            
            ClockHandViewIpad(currentDate: viewModel.currentDate)
                .rotationEffect(.degrees(zeroPosition))
            
            // Показ точки, куда «кидаем» категорию
            if let location = viewModel.dropLocation {
                Circle()
                    .fill(viewModel.draggedCategory?.color ?? .clear)
                    .frame(width: 30, height: 30) // Увеличенный размер для iPad
                    .position(location)
            }
            
            // Если редактируем задачу
            if viewModel.isEditingMode, let time = viewModel.previewTime, let task = viewModel.editingTask {
                ClockCenterViewIpad(
                    currentDate: time,
                    isDraggingStart: viewModel.isDraggingStart,
                    isDraggingEnd: viewModel.isDraggingEnd,
                    task: task
                )
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(height: UIScreen.main.bounds.width * 0.35) // Уменьшенный размер для iPad
        .padding()
        .animation(.spring(), value: tasksForSelectedDate)
        
        // Drop — создание новой задачи (Drag & Drop категории)
        .onDrop(of: [.text], isTargeted: nil) { providers, location in
            guard let category = viewModel.draggedCategory else { return false }
            let dropPoint = location
            viewModel.dropLocation = dropPoint
            
            let time = timeForLocation(dropPoint)
            
            // Используем selectedDate вместо currentDate
            let calendar = Calendar.current
            let selectedComponents = calendar.dateComponents([.year, .month, .day], from: viewModel.selectedDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            
            var newTaskComponents = DateComponents()
            newTaskComponents.year = selectedComponents.year
            newTaskComponents.month = selectedComponents.month
            newTaskComponents.day = selectedComponents.day
            newTaskComponents.hour = timeComponents.hour
            newTaskComponents.minute = timeComponents.minute
            
            let newTaskDate = calendar.date(from: newTaskComponents) ?? time
            
            // Создаём новую задачу
            let newTask = Task(
                id: UUID(),
                title: "Новая задача",
                startTime: newTaskDate,
                endTime: Calendar.current.date(byAdding: .hour, value: 1, to: newTaskDate) ?? newTaskDate,
                color: category.color,
                icon: category.iconName,
                category: category,
                isCompleted: false
            )
            
            // Добавляем через taskManagement
            viewModel.taskManagement.addTask(newTask)
            
            // Анимация исчезновения точки
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.dropLocation = nil
            }
            
            // Включаем режим редактирования, чтобы пользователь сразу мог двигать границы
            viewModel.isEditingMode = true
            viewModel.editingTask = newTask
            
            return true
        }
        .sheet(isPresented: $viewModel.showingTaskDetail) {
            if let task = viewModel.selectedTask {
                TaskEditorView(viewModel: viewModel,
                               isPresented: $viewModel.showingTaskDetail,
                               task: task)
            }
        }
    }
    
    // MARK: - Вспомогательные
    
    private var tasksForSelectedDate: [Task] {
        tasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: viewModel.selectedDate)
        }
    }
    
    private func timeForLocation(_ location: CGPoint) -> Date {
        let center = CGPoint(x: UIScreen.main.bounds.width * 0.45,
                             y: UIScreen.main.bounds.width * 0.45)
        let vector = CGVector(dx: location.x - center.x, dy: location.y - center.y)
        
        let angle = atan2(vector.dy, vector.dx)
        
        // Переводим в градусы и учитываем zeroPosition
        var degrees = angle * 180 / .pi
        degrees = (degrees - 90 - zeroPosition + 360).truncatingRemainder(dividingBy: 360)
        
        // 24 часа = 360 градусов => 1 час = 15 градусов
        let hours = degrees / 15
        let hourComponent = Int(hours)
        let minuteComponent = Int((hours - Double(hourComponent)) * 60)
        
        // Используем компоненты из selectedDate вместо currentDate
        var components = Calendar.current.dateComponents([.year, .month, .day], from: viewModel.selectedDate)
        components.hour = hourComponent
        components.minute = minuteComponent
        components.timeZone = TimeZone.current
        
        return Calendar.current.date(from: components) ?? viewModel.selectedDate
    }
}

