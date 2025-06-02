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
        ZStack {
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
                    
                    // Создаем previewTask для отображения дуги сразу
                    let time = viewModel.clockState.timeForLocation(
                        location,
                        screenWidth: UIScreen.main.bounds.width
                    )
                    let calendar = Calendar.current
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: viewModel.selectedDate)
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                    dateComponents.hour = timeComponents.hour
                    dateComponents.minute = timeComponents.minute
                    guard let adjustedTime = calendar.date(from: dateComponents) else { return false }
                    guard let endTime = calendar.date(byAdding: .hour, value: 1, to: adjustedTime) else { return false }
                    let previewTask = TaskOnRing(
                        id: UUID(),
                        startTime: adjustedTime,
                        endTime: endTime,
                        color: category.color,
                        icon: category.iconName,
                        category: category,
                        isCompleted: false
                    )
                    viewModel.previewTask = previewTask
                    
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
                }
            
            // Показываем previewTask, если он есть
            if let previewTask = viewModel.previewTask {
                GeometryReader { geometry in
                    let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    let radius = min(geometry.size.width, geometry.size.height) / 2
                    let configuration = TaskArcConfiguration(
                        isAnalog: viewModel.isAnalogArcStyle,
                        arcLineWidth: viewModel.taskArcLineWidth,
                        outerRingLineWidth: viewModel.outerRingLineWidth,
                        isEditingMode: false,
                        showTimeOnlyForActiveTask: viewModel.showTimeOnlyForActiveTask
                    )
                    let taskGeometry = TaskArcGeometry(
                        center: center,
                        radius: radius,
                        configuration: configuration,
                        task: previewTask
                    )
                    TaskArcContentView(
                        task: previewTask,
                        viewModel: viewModel,
                        geometry: taskGeometry,
                        configuration: configuration,
                        animationManager: TaskArcAnimationManager(),
                        gestureHandler: TaskArcGestureHandler(viewModel: viewModel, task: previewTask),
                        hapticsManager: TaskArcHapticsManager(),
                        timeFormatter: {
                            let formatter = DateFormatter()
                            formatter.timeStyle = .short
                            formatter.dateStyle = .none
                            return formatter
                        }(),
                        isDragging: .constant(false)
                    )
                    .opacity(0.7)
                }
            }
        }
    }
    
    private func createTaskWithValidatedCategory() {
        guard let previewTask = viewModel.previewTask else { return }
        
        Task {
            await MainActor.run {
                viewModel.taskManagement.addTask(previewTask)
                
                // Проверяем результат асинхронно
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let tasksForDate = viewModel.tasksForSelectedDate(viewModel.tasks)
                    if tasksForDate.contains(where: { $0.id == previewTask.id }) {
                        print("✅ DEBUG: Task successfully added to tasks list")
                        
                        // Включаем режим редактирования только после подтверждения
                        viewModel.isEditingMode = true
                        viewModel.editingTask = previewTask
                        viewModel.previewTask = nil // Очищаем предварительный просмотр
                    } else {
                        print("❌ DEBUG: Task NOT found in tasks list after adding")
                    }
                }
            }
        }
    }
}
