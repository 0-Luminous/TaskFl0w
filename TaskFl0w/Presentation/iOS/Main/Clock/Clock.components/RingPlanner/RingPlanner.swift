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

    // MARK: - Constants
    private enum Constants {
        static let defaultTaskDuration: TimeInterval = 3600 // 1 час
        static let categoryValidationDelay: TimeInterval = 0.1
        static let taskCreationDelay: TimeInterval = 0.2
        static let previewOpacity: Double = 0.7
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
                    handleTaskDrop(at: location)
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
                    .opacity(Constants.previewOpacity)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleTaskDrop(at location: CGPoint) -> Bool {
        guard let category = viewModel.draggedCategory else {
            print("⚠️ DEBUG: draggedCategory is nil")
            return false
        }
        
        do {
            let previewTask = try createPreviewTask(for: category, at: location)
            viewModel.previewTask = previewTask
            
            return try handleCategoryValidation(for: category)
        } catch {
            print("❌ DEBUG: Error creating task: \(error)")
            return false
        }
    }
    
    private func createPreviewTask(for category: TaskCategoryModel, at location: CGPoint) throws -> TaskOnRing {
        let time = viewModel.clockState.timeForLocation(
            location,
            screenWidth: UIScreen.main.bounds.width
        )
        
        let adjustedTime = try createAdjustedTime(from: time)
        let endTime = adjustedTime.addingTimeInterval(Constants.defaultTaskDuration)
        
        return TaskOnRing(
            id: UUID(),
            startTime: adjustedTime,
            endTime: endTime,
            color: category.color,
            icon: category.iconName,
            category: category,
            isCompleted: false
        )
    }
    
    private func createAdjustedTime(from time: Date) throws -> Date {
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: viewModel.selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        
        guard let adjustedTime = calendar.date(from: dateComponents) else {
            throw TaskCreationError.invalidTimeComponents
        }
        
        return adjustedTime
    }
    
    private func handleCategoryValidation(for category: TaskCategoryModel) throws -> Bool {
        let categoryExists = try checkCategoryExists(category)
        
        if categoryExists {
            createTaskWithValidatedCategory()
        } else {
            addCategoryAndCreateTask(category)
        }
        
        return true
    }
    
    private func checkCategoryExists(_ category: TaskCategoryModel) throws -> Bool {
        let categoryRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        categoryRequest.predicate = NSPredicate(format: "id == %@", category.id as CVarArg)
        
        let categoryResults = try viewModel.sharedState.context.fetch(categoryRequest)
        return !categoryResults.isEmpty
    }
    
    private func addCategoryAndCreateTask(_ category: TaskCategoryModel) {
        print("❌ DEBUG: Category NOT found in CoreData! Adding category first...")
        viewModel.categoryManagement.addCategory(category)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.categoryValidationDelay) {
            self.createTaskWithValidatedCategory()
        }
    }
    
    private func createTaskWithValidatedCategory() {
        guard let previewTask = viewModel.previewTask else { return }
        
        Task {
            await MainActor.run {
                viewModel.taskManagement.addTask(previewTask)
                
                // Проверяем результат асинхронно
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.taskCreationDelay) {
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

// MARK: - Error Handling

enum TaskCreationError: LocalizedError {
    case invalidTimeComponents
    case categoryNotFound
    case contextSaveError
    
    var errorDescription: String? {
        switch self {
        case .invalidTimeComponents:
            return "Не удалось создать корректное время"
        case .categoryNotFound:
            return "Категория не найдена"
        case .contextSaveError:
            return "Ошибка сохранения в Core Data"
        }
    }
}
