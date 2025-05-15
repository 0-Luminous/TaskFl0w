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
    let shouldDeleteTask: Bool
    let outerRingLineWidth: CGFloat
    
    // Инициализатор с параметром shouldDeleteTask, по умолчанию true
    init(color: Color, viewModel: ClockViewModel, zeroPosition: Double, shouldDeleteTask: Bool = true, outerRingLineWidth: CGFloat) {
        self.color = color
        self.viewModel = viewModel
        self.zeroPosition = zeroPosition
        self.shouldDeleteTask = shouldDeleteTask
        self.outerRingLineWidth = outerRingLineWidth
    }

    var body: some View {
        Circle()
            .stroke(color, lineWidth: outerRingLineWidth)
            .frame(
                width: UIScreen.main.bounds.width * 0.8,
                height: UIScreen.main.bounds.width * 0.8
            )
            .onDrop(of: [.text], isTargeted: nil) { providers, location in
                if let category = viewModel.draggedCategory {
                    // Обработка создания новой задачи
                    let time = viewModel.clockState.timeForLocation(
                        location,
                        screenWidth: UIScreen.main.bounds.width
                    )
                    
                    // Создаем новую дату на выбранном дне, а не на текущем
                    let calendar = Calendar.current
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: viewModel.selectedDate)
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                    dateComponents.hour = timeComponents.hour
                    dateComponents.minute = timeComponents.minute
                    
                    let adjustedTime = calendar.date(from: dateComponents) ?? time
                    let endTime = calendar.date(byAdding: .hour, value: 1, to: adjustedTime) ?? adjustedTime

                    // Создаём новую задачу
                    let newTask = TaskOnRing(
                        id: UUID(),
                        startTime: adjustedTime,
                        endTime: endTime,
                        color: category.color,
                        icon: category.iconName,
                        category: category,
                        isCompleted: false
                    )

                    viewModel.taskManagement.addTask(newTask)

                    // Включаем режим редактирования
                    viewModel.isEditingMode = true
                    viewModel.editingTask = newTask
                    // НЕ сбрасываем draggedCategory, чтобы можно было продолжать
                    // создавать задачи той же категории
                    return true
                }

                // Для удаления задачи drop не разрешаем
                return false
            }
    }
}
