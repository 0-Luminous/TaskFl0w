//
//  ClockTaskArcIOS.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI
import UIKit

struct ClockTaskArcIOS: View {
    let task: TaskOnRing
    @ObservedObject var viewModel: ClockViewModel
    let arcLineWidth: CGFloat
    @State private var isDragging: Bool = false
    @State private var isVisible: Bool = true
    @StateObject private var animationManager = TaskArcAnimationManager()
    @StateObject private var gestureHandler: TaskArcGestureHandler
    private let hapticsManager = TaskArcHapticsManager()
    
    // Кэшируем форматтер
    private let timeFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    init(task: TaskOnRing, viewModel: ClockViewModel, arcLineWidth: CGFloat) {
        self.task = task
        self.viewModel = viewModel
        self.arcLineWidth = arcLineWidth
        self._gestureHandler = StateObject(wrappedValue: TaskArcGestureHandler(viewModel: viewModel, task: task))
    }

    var body: some View {
        if !isVisible {
            EmptyView()
        } else {
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                
                let configuration = TaskArcConfiguration(
                    isAnalog: viewModel.isAnalogArcStyle,
                    arcLineWidth: arcLineWidth,
                    outerRingLineWidth: viewModel.outerRingLineWidth,
                    isEditingMode: viewModel.isEditingMode && task.id == viewModel.editingTask?.id,
                    showTimeOnlyForActiveTask: viewModel.showTimeOnlyForActiveTask
                )
                
                let taskGeometry = TaskArcGeometry(
                    center: center,
                    radius: radius,
                    configuration: configuration,
                    task: task
                )
                
                TaskArcContentView(
                    task: task,
                    viewModel: viewModel,
                    geometry: taskGeometry,
                    configuration: configuration,
                    animationManager: animationManager,
                    gestureHandler: gestureHandler,
                    hapticsManager: hapticsManager,
                    timeFormatter: timeFormatter,
                    isDragging: $isDragging
                )
            }
            .onAppear {
                animationManager.startAppearanceAnimation()
            }
            .onReceive(NotificationCenter.default.publisher(for: .startTaskRemovalAnimation)) { notification in
                if let taskToRemove = notification.userInfo?["task"] as? TaskOnRing,
                   taskToRemove.id == task.id {
                    print("🎬 Получено уведомление об удалении задачи: \(task.id)")
                    animationManager.startAnimatedRemoval(task: task, taskManagement: viewModel.taskManagement)
                }
            }
            .onChange(of: isDragging) { oldValue, newValue in
                handleDragStateChange(oldValue: oldValue, newValue: newValue)
            }
            .zIndex(zIndexValue)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleDragStateChange(oldValue: Bool, newValue: Bool) {
        guard oldValue != newValue else { return }
        
        if newValue && task.id == viewModel.draggedTask?.id && isVisible {
            DispatchQueue.main.asyncAfter(deadline: .now() + TaskArcConstants.hapticFeedbackDelay) {
                checkForRemoval()
            }
        }
        
        // Если перетаскивание завершилось, сбрасываем высокочастотное обновление
        if !newValue {
            gestureHandler.resetLastHourComponent()
        }
    }
    
    private func checkForRemoval() {
        if isDragging && 
           viewModel.draggedTask?.id == task.id && 
           isVisible && 
           viewModel.isDraggingOutside {
            
            animationManager.startDisappearanceAnimation {
                viewModel.taskManagement.removeTask(task)
                isVisible = false
            }
        }
    }
    
    private var isEditingTask: Bool {
        viewModel.isEditingMode && task.id == viewModel.editingTask?.id
    }
    
    private var isDraggedTask: Bool {
        isDragging || viewModel.draggedTask?.id == task.id
    }
    
    private var zIndexValue: Double {
        if isEditingTask {
            return 1000 // Редактируемая задача - максимальный приоритет
        } else if isDraggedTask {
            return 500 // Перетаскиваемая задача - средний приоритет
        } else {
            return 0 // Обычные задачи
        }
    }
}
