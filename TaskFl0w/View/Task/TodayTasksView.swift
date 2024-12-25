//
//  TodayTasksView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct TodayTasksView: View {
    @ObservedObject var viewModel: ClockViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTask: Task?
    @State private var isShowingTaskEditor = false
    
    /// Фильтрация задач на сегодня
    var todaysTasks: [Task] {
        viewModel.tasks.filter {
            Calendar.current.isDate($0.startTime, inSameDayAs: Date())
        }
        // Можно добавить сортировку, например, по времени:
        .sorted(by: { $0.startTime < $1.startTime })
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(todaysTasks) { task in
                    HStack {
                        Circle()
                            .fill(task.category.color)
                            .frame(width: 12, height: 12)
                        
                        VStack(alignment: .leading) {
                            Text(task.title)
                                .font(.headline)
                            Text("\(timeFormatter.string(from: task.startTime)) - \(timeFormatter.string(from: task.startTime.addingTimeInterval(task.duration)))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: task.category.iconName)
                            .foregroundColor(task.category.color)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTask = task
                        isShowingTaskEditor = true
                    }
                }
                .onDelete { indexSet in
                    deleteTasks(at: indexSet)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Сегодняшние задачи")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isShowingTaskEditor) {
                if let task = selectedTask {
                    TaskEditorView(viewModel: viewModel,
                                   isPresented: $isShowingTaskEditor,
                                   task: task)
                }
            }
        }
    }
    
    // MARK: - Удаление
    
    private func deleteTasks(at offsets: IndexSet) {
        let tasksToDelete = offsets.map { todaysTasks[$0] }
        for task in tasksToDelete {
            viewModel.removeTask(task)
        }
    }
}

//#if DEBUG
//#Preview {
//    // Пример тестовой категории
//    let sampleCategory = TaskCategoryModel(
//        id: UUID(),
//        rawValue: "Demo Category",
//        iconName: "star.fill",
//        color: .blue
//    )
//    
//    // Пример тестовой задачи
//    let sampleTask = Task(
//        id: UUID(),
//        title: "Test Task",
//        startTime: Date(),
//        duration: 3600, // 1 час
//        color: .blue,
//        icon: "star.fill",
//        category: sampleCategory,
//        isCompleted: false
//    )
//    
//    // Создаём и наполняем ClockViewModel
//    let sampleVM = ClockViewModel()
//    sampleVM.tasks = [sampleTask]
//
//    // Возвращаем TodayTasksView для превью
//    return TodayTasksView(viewModel: sampleVM)
//}
//#endif
