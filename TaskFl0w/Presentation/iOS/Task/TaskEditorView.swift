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
                    .disabled(!isValidTask())
                }
            }
            .onAppear {
                if let existingTask = task {
                    title = existingTask.title
                    selectedStartDate = existingTask.startTime
                    selectedEndDate = existingTask.endTime
                    selectedCategory = existingTask.category
                } else {
                    // Для новой задачи устанавливаем время окончания на час позже времени начала
                    selectedEndDate = Calendar.current.date(byAdding: .hour, value: 1, to: selectedStartDate) ?? selectedStartDate
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
    
    private func isValidTask() -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedTitle.isEmpty && 
               selectedStartDate < selectedEndDate && 
               selectedCategory != nil
    }
    
    private func saveTask() {
        guard selectedStartDate < selectedEndDate else { 
            print("Некорректное время задачи")
            return 
        }
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        guard let category = selectedCategory else { return }
        
        if let existingTask = task {
            var updatedTask = existingTask
            updatedTask.title = trimmedTitle
            updatedTask.startTime = selectedStartDate
            updatedTask.endTime = selectedEndDate
            updatedTask.category = category
            updatedTask.color = category.color
            updatedTask.icon = category.iconName
            
            viewModel.taskManagement.updateTask(updatedTask)
        } else {
            let newTask = Task(
                id: UUID(),
                title: trimmedTitle,
                startTime: selectedStartDate,
                endTime: selectedEndDate,
                color: category.color,
                icon: category.iconName,
                category: category,
                isCompleted: false
            )
            viewModel.taskManagement.addTask(newTask)
        }
    }
}
