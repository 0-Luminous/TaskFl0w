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
                guard let category = viewModel.draggedCategory else { 
                    print("⚠️ DEBUG: draggedCategory is nil")
                    return false 
                }
                
                print("✅ DEBUG: draggedCategory available: \(category.rawValue)")
                
                // Проверяем категорию в CoreData и создаем при необходимости
                let categoryRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
                categoryRequest.predicate = NSPredicate(format: "id == %@", category.id as CVarArg)

                do {
                    let categoryResults = try viewModel.sharedState.context.fetch(categoryRequest)
                    if categoryResults.isEmpty {
                        print("❌ DEBUG: Category NOT found in CoreData! Adding category first...")
                        viewModel.categoryManagement.addCategory(category)
                        
                        // Ждем небольшую задержку для сохранения категории
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            createTaskWithValidatedCategory()
                        }
                        return true
                    } else {
                        print("✅ DEBUG: Category found in CoreData")
                        createTaskWithValidatedCategory()
                        return true
                    }
                } catch {
                    print("❌ DEBUG: Error checking category in CoreData: \(error)")
                    return false
                }
                
                func createTaskWithValidatedCategory() {
                    let time = viewModel.clockState.timeForLocation(
                        location,
                        screenWidth: UIScreen.main.bounds.width
                    )
                    
                    print("✅ DEBUG: calculated time: \(time)")
                    
                    let calendar = Calendar.current
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: viewModel.selectedDate)
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                    dateComponents.hour = timeComponents.hour
                    dateComponents.minute = timeComponents.minute
                    
                    guard let adjustedTime = calendar.date(from: dateComponents) else {
                        print("❌ DEBUG: Failed to create adjustedTime from components")
                        return
                    }
                    
                    guard let endTime = calendar.date(byAdding: .hour, value: 1, to: adjustedTime) else {
                        print("❌ DEBUG: Failed to create endTime")
                        return
                    }

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

                    // Используем async для надежного добавления
                    Task {
                        await MainActor.run {
                            viewModel.taskManagement.addTask(newTask)
                            
                            // Проверяем результат асинхронно
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                let tasksForDate = viewModel.tasksForSelectedDate(viewModel.tasks)
                                if tasksForDate.contains(where: { $0.id == newTask.id }) {
                                    print("✅ DEBUG: Task successfully added to tasks list")
                                    
                                    // Включаем режим редактирования только после подтверждения
                                    viewModel.isEditingMode = true
                                    viewModel.editingTask = newTask
                                } else {
                                    print("❌ DEBUG: Task NOT found in tasks list after adding")
                                }
                            }
                        }
                    }
                }
            }
    }
}
