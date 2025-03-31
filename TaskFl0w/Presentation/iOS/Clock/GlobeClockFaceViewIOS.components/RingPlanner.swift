//
//  RingPlanner.swift
//  TaskFl0w
//
//  Created by Yan on 31/3/25.
//

import SwiftUI

struct RingPlanner: View {
    let color: Color
    @ObservedObject var viewModel: ClockViewModel
    let zeroPosition: Double

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 20)
            .frame(
                width: UIScreen.main.bounds.width * 0.8,
                height: UIScreen.main.bounds.width * 0.8
            )
            .onDrop(of: [.text], isTargeted: nil) { providers, location in
                if let task = viewModel.draggedTask {
                    // Обработка удаления задачи
                    viewModel.taskManagement.removeTask(task)
                    return true
                }

                if let category = viewModel.draggedCategory {
                    // Обработка создания новой задачи
                    let time = timeForLocation(location)

                    // Используем selectedDate для даты
                    let calendar = Calendar.current
                    let selectedComponents = calendar.dateComponents(
                        [.year, .month, .day], from: viewModel.selectedDate)
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

                    var newTaskComponents = DateComponents()
                    newTaskComponents.year = selectedComponents.year
                    newTaskComponents.month = selectedComponents.month
                    newTaskComponents.day = selectedComponents.day
                    newTaskComponents.hour = timeComponents.hour
                    newTaskComponents.minute = timeComponents.minute
                    newTaskComponents.timeZone = TimeZone.current

                    let newTaskDate = calendar.date(from: newTaskComponents) ?? time

                    // Создаём новую задачу
                    let newTask = TaskOnRing(
                        id: UUID(),
                        title: "Новая задача",
                        startTime: newTaskDate,
                        endTime: Calendar.current.date(byAdding: .hour, value: 1, to: newTaskDate)
                            ?? newTaskDate,
                        color: category.color,
                        icon: category.iconName,
                        category: category,
                        isCompleted: false
                    )

                    viewModel.taskManagement.addTask(newTask)

                    // Включаем режим редактирования
                    viewModel.isEditingMode = true
                    viewModel.editingTask = newTask
                    return true
                }

                return false
            }
    }

    // Функция для вычисления времени на основе положения
    private func timeForLocation(_ location: CGPoint) -> Date {
        let center = CGPoint(
            x: UIScreen.main.bounds.width * 0.4,
            y: UIScreen.main.bounds.width * 0.4
        )
        let vector = CGVector(dx: location.x - center.x, dy: location.y - center.y)

        let angle = atan2(vector.dy, vector.dx)

        // Переводим в градусы и учитываем zeroPosition
        var degrees = angle * 180 / .pi
        degrees = (degrees - 90 - zeroPosition + 360).truncatingRemainder(dividingBy: 360)

        // 24 часа = 360 градусов => 1 час = 15 градусов
        let hours = degrees / 15
        let hourComponent = Int(hours)
        let minuteComponent = Int((hours - Double(hourComponent)) * 60)

        var components = Calendar.current.dateComponents(
            [.year, .month, .day], from: viewModel.selectedDate)
        components.hour = hourComponent
        components.minute = minuteComponent
        components.timeZone = TimeZone.current

        return Calendar.current.date(from: components) ?? viewModel.selectedDate
    }
}
