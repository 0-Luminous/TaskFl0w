//
//  MainClockFaceView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct GlobleClockFaceViewIpad: View {
    let currentDate: Date
    let tasks: [TaskOnRing]
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
        GeometryReader { geometry in
            ZStack {
                // Круглый светло-серый фон часов с тонкой серой границей
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)

                // Маркеры часов (24 шт.)
                ForEach(0..<24) { hour in
                    let angle = Double(hour) * (360.0 / 24.0) + zeroPosition
                    ClockMarkerForIpad(hour: hour, style: clockStyle.markerStyle)
                        .rotationEffect(.degrees(angle))
                        .frame(width: geometry.size.width * 0.7, height: geometry.size.height * 0.7)
                }

                // Задачи
                TaskArcsViewIpad(
                    tasks: tasksForSelectedDate,
                    viewModel: viewModel
                )

                // Стрелка часов
                ClockHandViewIpad(currentDate: viewModel.currentDate)
                    .rotationEffect(.degrees(zeroPosition))

                // Показ точки, куда «кидаем» категорию
                if let location = viewModel.dropLocation {
                    Circle()
                        .fill(viewModel.draggedCategory?.color ?? .clear)
                        .frame(width: 30, height: 30)  // Увеличенный размер для iPad
                        .position(location)
                }

                // Если редактируем задачу
                if viewModel.isEditingMode, let time = viewModel.previewTime,
                    let task = viewModel.editingTask
                {
                    ClockCenterViewIpad(
                        currentDate: time,
                        isDraggingStart: viewModel.isDraggingStart,
                        isDraggingEnd: viewModel.isDraggingEnd,
                        task: task
                    )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding()
        .animation(.spring(), value: tasksForSelectedDate)

        // Drop — создание новой задачи (Drag & Drop категории)
        .onDrop(of: [.text], isTargeted: nil) { providers, location in
            guard let category = viewModel.draggedCategory else { return false }
            let dropPoint = location
            viewModel.dropLocation = dropPoint

            // Используем метод из viewModel вместо локального
            let time = viewModel.timeForLocation(dropPoint, screenWidth: UIScreen.main.bounds.width)

            // Используем selectedDate вместо currentDate
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
    }

    // MARK: - Вспомогательные

    private var tasksForSelectedDate: [TaskOnRing] {
        // Используем метод из viewModel
        return viewModel.tasksForSelectedDate(tasks)
    }
}
