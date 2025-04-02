//
//  RingPlanner.swift
//  TaskFl0w
//
//  Created by Yan on 31/3/25.
//

import Foundation
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
                    let center = CGPoint(
                        x: UIScreen.main.bounds.width * 0.4,
                        y: UIScreen.main.bounds.width * 0.4
                    )
                    let time = RingTimeCalculator.timeForLocation(
                        location,
                        center: center,
                        baseDate: viewModel.selectedDate,
                        zeroPosition: zeroPosition
                    )

                    // Создаём новую задачу
                    let newTask = TaskOnRing(
                        id: UUID(),
                        title: "Новая задача",
                        startTime: time,
                        endTime: Calendar.current.date(byAdding: .hour, value: 1, to: time)
                            ?? time,
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
}
