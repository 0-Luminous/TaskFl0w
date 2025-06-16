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
                        hapticsManager: HapticsManager(),
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
        // 1. Быстрая проверка состояния
        guard let category = viewModel.draggedCategory,
              viewModel.previewTask == nil else {
            return false
        }
        
        do {
            // 2. Создаем задачу и проверяем категорию параллельно
            let (newPreviewTask, categoryExists) = try (
                createPreviewTask(for: category, at: location),
                checkCategoryExists(category)
            )
            
            // 3. Обновляем UI и создаем задачу в одном асинхронном блоке
            DispatchQueue.main.async {
                // Показываем предпросмотр
                self.viewModel.previewTask = newPreviewTask
                
                // Создаем задачу сразу, без дополнительных задержек
                if categoryExists {
                    self.createTask(newPreviewTask)
                } else {
                    // Если категории нет, добавляем её и создаем задачу
                    self.viewModel.categoryManagement.addCategory(category)
                    self.createTask(newPreviewTask)
                }
            }
            
            return true
            
        } catch {
            print("❌ DEBUG: Error in handleTaskDrop: \(error)")
            return false
        }
    }
    
    private func createTask(_ task: TaskOnRing) {
        // Создаем задачу
        viewModel.taskManagement.addTask(task)
        
        // Проверяем успешность создания с минимальной задержкой
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let tasksForDate = self.viewModel.tasksForSelectedDate(self.viewModel.tasks)
            if tasksForDate.contains(where: { $0.id == task.id }) {
                // Включаем режим редактирования
                self.viewModel.isEditingMode = true
                self.viewModel.editingTask = task
            }
            
            // Очищаем предпросмотр
            self.viewModel.previewTask = nil
        }
    }
    
    private func checkCategoryExists(_ category: TaskCategoryModel) throws -> Bool {
        let categoryRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        categoryRequest.predicate = NSPredicate(format: "id == %@", category.id as CVarArg)
        categoryRequest.fetchLimit = 1 // Оптимизация: запрашиваем только одну запись
        
        let count = try viewModel.sharedState.context.count(for: categoryRequest)
        return count > 0
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
}

// MARK: - Error Handling

enum TaskCreationError: LocalizedError {
    case invalidTimeComponents
    case categoryNotFound
    case contextSaveError
    case taskNotCreated
    
    var errorDescription: String? {
        switch self {
        case .invalidTimeComponents:
            return "Не удалось создать корректное время"
        case .categoryNotFound:
            return "Категория не найдена"
        case .contextSaveError:
            return "Ошибка сохранения в Core Data"
        case .taskNotCreated:
            return "Задача не была создана"
        }
    }
}
