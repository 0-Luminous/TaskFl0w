//
//  TaskEditorView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct TaskEditorView: View {
    @ObservedObject var viewModel: ClockViewModel
    @Binding var isPresented: Bool
    
    /// Если передадим существующую задачу, будем её редактировать. Иначе создадим новую.
    var task: Task?
    
    // Локальные стейты для полей формы
    @State private var title: String = ""
    @State private var selectedStartDate: Date = Date()
    @State private var selectedEndDate: Date = Date()
    @State private var selectedCategory: TaskCategoryModel?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Название задачи", text: $title)
                    .textInputAutocapitalization(.sentences)
                
                Section("Время") {
                    DatePicker("Начало", selection: $selectedStartDate, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Окончание", selection: $selectedEndDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Категория") {
                    Picker("Выберите категорию", selection: $selectedCategory) {
                        ForEach(viewModel.categories, id: \.id) { category in
                            Text(category.rawValue).tag(Optional(category))
                        }
                    }
                }
            }
            .navigationTitle(task == nil ? "Новая задача" : "Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Отмена") {
                    closeEditor()
                },
                trailing: Button("Сохранить") {
                    saveTask()
                    closeEditor()
                }
            )
            .onAppear {
                // Если редактируем задачу, подтягиваем её данные
                if let existingTask = task {
                    title = existingTask.title
                    selectedStartDate = existingTask.startTime
                    selectedEndDate = existingTask.startTime.addingTimeInterval(existingTask.duration)
                    selectedCategory = existingTask.category
                }
            }
        }
    }
    
    // MARK: - Методы
    
    private func closeEditor() {
        if isPresented {
            isPresented = false
        } else {
            dismiss()
        }
    }
    
    private func saveTask() {
        // Вычисляем duration
        let duration = selectedEndDate.timeIntervalSince(selectedStartDate)
        guard duration >= 0 else { return }
        
        if let existingTask = task {
            // Обновляем существующую задачу
            // 1. Обновим title
            if let index = viewModel.tasks.firstIndex(where: { $0.id == existingTask.id }) {
                viewModel.tasks[index].title = title
            }
            // 2. Обновим время
            viewModel.updateTaskStartTime(existingTask, newStartTime: selectedStartDate)
            viewModel.updateTaskDuration(existingTask, newEndTime: selectedEndDate)
            
            // 3. Обновим категорию (иконку/цвет)
            if let category = selectedCategory, let idx = viewModel.tasks.firstIndex(where: { $0.id == existingTask.id }) {
                viewModel.tasks[idx].category = category
                viewModel.tasks[idx].color = category.color
                viewModel.tasks[idx].icon = category.iconName
            }
            
        } else {
            // Создаём новую
            guard let category = selectedCategory else { return }
            
            let newTask = Task(
                id: UUID(),
                title: title,
                startTime: selectedStartDate,
                duration: duration,
                color: category.color,
                icon: category.iconName,
                category: category,
                isCompleted: false
            )
            viewModel.addTask(newTask)
        }
    }
}
