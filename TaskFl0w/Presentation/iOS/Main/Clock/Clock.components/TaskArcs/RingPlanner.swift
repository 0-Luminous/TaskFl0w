//
//  RingPlanner.swift
//  TaskFl0w
//
//  Created by Yan on 31/3/25.
//

import Foundation
import SwiftUI
import CoreData

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
                // Добавляем дополнительные проверки
                guard let category = viewModel.draggedCategory else { 
                    print("⚠️ DEBUG: draggedCategory is nil")
                    return false 
                }
                
                print("✅ DEBUG: draggedCategory available: \(category.rawValue)")
                
                // ДОБАВЛЯЕМ ПРОВЕРКУ КАТЕГОРИИ В COREDATA
                let categoryRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
                categoryRequest.predicate = NSPredicate(format: "id == %@", category.id as CVarArg)

                do {
                    let categoryResults = try viewModel.sharedState.context.fetch(categoryRequest)
                    if categoryResults.isEmpty {
                        print("❌ DEBUG: Category NOT found in CoreData! Adding category first...")
                        viewModel.categoryManagement.addCategory(category)
                    } else {
                        print("✅ DEBUG: Category found in CoreData")
                    }
                } catch {
                    print("❌ DEBUG: Error checking category in CoreData: \(error)")
                }
                
                // Обработка создания новой задачи
                let time = viewModel.clockState.timeForLocation(
                    location,
                    screenWidth: UIScreen.main.bounds.width
                )
                
                print("✅ DEBUG: calculated time: \(time)")
                
                // Создаем новую дату на выбранном дне, а не на текущем
                let calendar = Calendar.current
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: viewModel.selectedDate)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute
                
                // Добавляем проверку создания даты
                guard let adjustedTime = calendar.date(from: dateComponents) else {
                    print("❌ DEBUG: Failed to create adjustedTime from components")
                    return false
                }
                
                guard let endTime = calendar.date(byAdding: .hour, value: 1, to: adjustedTime) else {
                    print("❌ DEBUG: Failed to create endTime")
                    return false
                }

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

                print("✅ DEBUG: Created new task: \(newTask.id)")

                // Добавляем задачу и проверяем результат
                viewModel.taskManagement.addTask(newTask)
                
                // Проверяем, что задача действительно добавилась
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let tasksForDate = viewModel.tasksForSelectedDate(viewModel.tasks)
                    if tasksForDate.contains(where: { $0.id == newTask.id }) {
                        print("✅ DEBUG: Task successfully added to tasks list")
                    } else {
                        print("❌ DEBUG: Task NOT found in tasks list after adding")
                    }
                }

                // Включаем режим редактирования
                viewModel.isEditingMode = true
                viewModel.editingTask = newTask
                
                print("✅ DEBUG: Drop operation completed successfully")
                return true
            }
    }
}
