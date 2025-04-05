//
//  RingPlanner.swift
//  TaskFl0w
//
//  Created by Yan on 31/3/25.
//

import Foundation
import SwiftUI
import UIKit

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
                    viewModel.taskManager.deleteTask(task)
                    return true
                }

                if let category = viewModel.draggedCategory {
                    // Обработка создания новой задачи
                    let time = viewModel.clockState.timeForLocation(
                        location,
                        screenWidth: UIScreen.main.bounds.width
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

                    viewModel.taskManager.createTaskAtLocation(
                        location: location, screenWidth: UIScreen.main.bounds.width,
                        clockState: viewModel.clockState)

                    // Включаем режим редактирования
                    viewModel.isEditingMode = true
                    viewModel.editingTask = newTask
                    return true
                }

                return false
            }
    }
}
