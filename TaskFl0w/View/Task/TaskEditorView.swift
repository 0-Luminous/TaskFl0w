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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        closeEditor()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        saveTask()
                        closeEditor()
                    }
                }
            }
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
        let duration = selectedEndDate.timeIntervalSince(selectedStartDate)
        guard duration.isFinite && duration > 0 else { 
            print("Некорректная длительность задачи")
            return 
        }
        
        if let existingTask = task {
            var updatedTask = existingTask
            updatedTask.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedTask.startTime = selectedStartDate
            updatedTask.duration = duration
            
            if let category = selectedCategory {
                updatedTask.category = category
                updatedTask.color = category.color
                updatedTask.icon = category.iconName
            }
            
            viewModel.taskManagement.updateTask(updatedTask)
        } else {
            guard let category = selectedCategory else { return }
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            
            let newTask = Task(
                id: UUID(),
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                startTime: selectedStartDate,
                duration: duration,
                color: category.color,
                icon: category.iconName,
                category: category,
                isCompleted: false
            )
            viewModel.taskManagement.addTask(newTask)
        }
    }
}
