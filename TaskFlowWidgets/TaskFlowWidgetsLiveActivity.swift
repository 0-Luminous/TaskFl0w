//
//  TaskFlowWidgetsLiveActivity.swift
//  TaskFlowWidgets
//
//  Created by Yan on 30/4/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

// Переименовываем структуру Task в TodoTask, чтобы избежать конфликта с Swift.Task
struct TodoTask: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var isCompleted: Bool
    var category: String
}

struct TaskFlowWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Динамические свойства для активности
        var categories: [String]
        var currentCategory: String
        var timeRemaining: TimeInterval
        var tasks: [TodoTask] // Используем переименованный тип
    }

    // Фиксированные свойства
    var name: String
    var totalTime: TimeInterval
}

struct TaskClockView: View {
    var categories: [String]
    var currentCategory: String
    var timeRemaining: TimeInterval
    var totalTime: TimeInterval
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: size/2, y: size/2)
            let radius = size/2 - 4
            
            ZStack {
                // Фоновый круг
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: size, height: size)
                
                // Секторы категорий
                ForEach(0..<categories.count, id: \.self) { index in
                    let startAngle = Angle(degrees: Double(index) * (360.0 / Double(categories.count)))
                    let endAngle = Angle(degrees: Double(index + 1) * (360.0 / Double(categories.count)))
                    let isActive = categories[index] == currentCategory
                    
                    Path { path in
                        path.move(to: center)
                        path.addArc(
                            center: center,
                            radius: radius,
                            startAngle: startAngle,
                            endAngle: endAngle,
                            clockwise: false
                        )
                        path.closeSubpath()
                    }
                    .fill(isActive ? Color.blue : Color.gray.opacity(0.5))
                }
                
                // Внутренний круг для текста
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.6, height: size * 0.6)
                
                // Текст с оставшимся временем
                VStack {
                    Text(formatTime(timeRemaining))
                        .font(.system(size: size * 0.2, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(currentCategory)
                        .font(.system(size: size * 0.1))
                        .foregroundColor(.white)
                }
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Компонент для отображения задачи
struct TodoTaskRow: View {
    var task: TodoTask
    
    var body: some View {
        HStack {
            Circle()
                .fill(task.isCompleted ? Color.green : Color.blue)
                .frame(width: 12, height: 12)
            
            Text(task.title)
                .font(.system(size: 14))
                .lineLimit(1)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// Компонент для отображения списка задач
struct TodoTaskList: View {
    var tasks: [TodoTask]
    var category: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(category): \(filteredTasks.count) задач")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 4)
            
            if filteredTasks.isEmpty {
                Text("Нет активных задач")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .padding(.vertical, 2)
            } else {
                ForEach(filteredTasks.prefix(4)) { task in
                    TodoTaskRow(task: task)
                }
                
                if filteredTasks.count > 4 {
                    Text("+ ещё \(filteredTasks.count - 4)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(.top, 2)
                }
            }
        }
    }
    
    private var filteredTasks: [TodoTask] {
        return tasks.filter { $0.category == category }
    }
}

struct TaskFlowWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TaskFlowWidgetsAttributes.self) { context in
            // Интерфейс для экрана блокировки
            VStack {
                Text(context.attributes.name)
                    .font(.headline)
                    .padding(.top, 8)
                
                TaskClockView(
                    categories: context.state.categories,
                    currentCategory: context.state.currentCategory,
                    timeRemaining: context.state.timeRemaining,
                    totalTime: context.attributes.totalTime
                )
                .padding(16)
                
                TodoTaskList(
                    tasks: context.state.tasks,
                    category: context.state.currentCategory
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Расширенный UI для Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.name)
                        .font(.headline)
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatTime(context.state.timeRemaining))
                        .font(.headline)
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack {
                        TaskClockView(
                            categories: context.state.categories,
                            currentCategory: context.state.currentCategory,
                            timeRemaining: context.state.timeRemaining, 
                            totalTime: context.attributes.totalTime
                        )
                        .frame(height: 100)
                        
                        // Добавляем список задач в нижнюю часть Dynamic Island
                        TodoTaskList(
                            tasks: context.state.tasks,
                            category: context.state.currentCategory
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            } compactLeading: {
                Text(formatTime(context.state.timeRemaining))
            } compactTrailing: {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Text(String(context.state.currentCategory.prefix(1)))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    )
            } minimal: {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Text(String(context.state.currentCategory.prefix(1)))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            .widgetURL(URL(string: "taskflow://open"))
            .keylineTint(Color.blue)
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

extension TaskFlowWidgetsAttributes {
    fileprivate static var preview: TaskFlowWidgetsAttributes {
        TaskFlowWidgetsAttributes(
            name: "Рабочая Сессия",
            totalTime: 3600
        )
    }
}

extension TaskFlowWidgetsAttributes.ContentState {
    fileprivate static var workSession: TaskFlowWidgetsAttributes.ContentState {
        TaskFlowWidgetsAttributes.ContentState(
            categories: ["Работа", "Перерыв", "Учеба", "Хобби"],
            currentCategory: "Работа",
            timeRemaining: 1500,
            tasks: [
                TodoTask(id: "1", title: "Ответить на письма", isCompleted: false, category: "Работа"),
                TodoTask(id: "2", title: "Подготовить отчет", isCompleted: false, category: "Работа"),
                TodoTask(id: "3", title: "Созвон с клиентом", isCompleted: true, category: "Работа"),
                TodoTask(id: "4", title: "Анализ данных", isCompleted: false, category: "Работа"),
                TodoTask(id: "5", title: "Обновить резюме", isCompleted: false, category: "Работа")
            ]
        )
    }
     
    fileprivate static var breakSession: TaskFlowWidgetsAttributes.ContentState {
        TaskFlowWidgetsAttributes.ContentState(
            categories: ["Работа", "Перерыв", "Учеба", "Хобби"],
            currentCategory: "Перерыв",
            timeRemaining: 300,
            tasks: [
                TodoTask(id: "1", title: "Ответить на письма", isCompleted: false, category: "Работа"),
                TodoTask(id: "2", title: "Подготовить отчет", isCompleted: false, category: "Работа"),
                TodoTask(id: "6", title: "Выпить чай", isCompleted: false, category: "Перерыв"),
                TodoTask(id: "7", title: "Размяться", isCompleted: true, category: "Перерыв")
            ]
        )
    }
}

#Preview("Notification", as: .content, using: TaskFlowWidgetsAttributes.preview) {
   TaskFlowWidgetsLiveActivity()
} contentStates: {
    TaskFlowWidgetsAttributes.ContentState.workSession
    TaskFlowWidgetsAttributes.ContentState.breakSession
}

// Функции для управления Live Activity
func startLiveActivity(tasks: [TodoTask]) {
    let attributes = TaskFlowWidgetsAttributes(
        name: "Рабочая Сессия",
        totalTime: 3600
    )
    
    let contentState = TaskFlowWidgetsAttributes.ContentState(
        categories: ["Работа", "Перерыв", "Учеба", "Хобби"],
        currentCategory: "Работа",
        timeRemaining: 1500,
        tasks: tasks
    )
    
    do {
        let activity = try Activity.request(
            attributes: attributes,
            contentState: contentState
        )
        print("Started Live Activity with ID: \(activity.id)")
    } catch {
        print("Error starting Live Activity: \(error.localizedDescription)")
    }
}

func updateLiveActivity(timeRemaining: TimeInterval, currentCategory: String, tasks: [TodoTask]? = nil) {
    guard let activity = Activity<TaskFlowWidgetsAttributes>.activities.first else {
        print("No active Live Activity found")
        return
    }
    
    let updatedState = TaskFlowWidgetsAttributes.ContentState(
        categories: activity.content.state.categories,
        currentCategory: currentCategory,
        timeRemaining: timeRemaining,
        tasks: tasks ?? activity.content.state.tasks
    )
    
    Task {
        await activity.update(using: updatedState)
    }
}

func endLiveActivity() {
    guard let activity = Activity<TaskFlowWidgetsAttributes>.activities.first else {
        print("No active Live Activity found")
        return
    }
    
    Task {
        await activity.end(dismissalPolicy: .immediate)
    }
}

// Функция для обновления виджета с новыми задачами
func updateWidgetTasks(tasks: [TodoTask]) {
    guard let activity = Activity<TaskFlowWidgetsAttributes>.activities.first else {
        print("No active Live Activity found")
        return
    }
    
    let updatedState = TaskFlowWidgetsAttributes.ContentState(
        categories: activity.content.state.categories,
        currentCategory: activity.content.state.currentCategory,
        timeRemaining: activity.content.state.timeRemaining,
        tasks: tasks
    )
    
    Task {
        await activity.update(using: updatedState)
    }
}
