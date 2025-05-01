//
//  TaskFlowWidgets.swift
//  TaskFlowWidgets
//
//  Created by Yan on 30/4/25.
//

import WidgetKit
import SwiftUI

// Используем структуру с таким же определением, как в LiveActivity
struct WidgetTodoTask: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var isCompleted: Bool
    var category: String
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    var tasks: [WidgetTodoTask] = []
    var categories: [String] = ["Работа", "Перерыв", "Учеба", "Хобби"]
    var currentCategory: String = "Работа"
}

struct Provider: AppIntentTimelineProvider {
    // Получение тестовых данных для предпросмотра
    func getSampleTasks() -> [WidgetTodoTask] {
        return [
            WidgetTodoTask(id: "1", title: "Ответить на письма", isCompleted: false, category: "Работа"),
            WidgetTodoTask(id: "2", title: "Подготовить отчет", isCompleted: false, category: "Работа"),
            WidgetTodoTask(id: "3", title: "Созвон с клиентом", isCompleted: true, category: "Работа"),
            WidgetTodoTask(id: "4", title: "Прочитать главу книги", isCompleted: false, category: "Учеба"),
            WidgetTodoTask(id: "5", title: "Выпить чай", isCompleted: false, category: "Перерыв"),
            WidgetTodoTask(id: "6", title: "Размяться", isCompleted: true, category: "Перерыв")
        ]
    }
    
    func placeholder(in context: Context) -> SimpleEntry {
        var entry = SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
        entry.tasks = getSampleTasks()
        return entry
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        var entry = SimpleEntry(date: Date(), configuration: configuration)
        entry.tasks = getSampleTasks()
        return entry
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        let sampleTasks = getSampleTasks()

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            var entry = SimpleEntry(date: entryDate, configuration: configuration)
            entry.tasks = sampleTasks
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
}

// Компонент для отображения циферблата с другим именем
struct WidgetClockView: View {
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
                        .font(.system(size: size * 0.15, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(currentCategory)
                        .font(.system(size: size * 0.08))
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

struct WidgetTaskView: View {
    var categories: [String]
    var currentCategory: String
    var tasks: [WidgetTodoTask] 
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(currentCategory)
                .font(.headline)
                .padding(.bottom, 4)
            
            let filteredTasks = tasks.filter { $0.category == currentCategory }
            
            if filteredTasks.isEmpty {
                Text("Нет активных задач")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                ForEach(filteredTasks.prefix(5)) { task in
                    HStack {
                        Circle()
                            .fill(task.isCompleted ? Color.green : Color.blue)
                            .frame(width: 10, height: 10)
                        
                        Text(task.title)
                            .font(.system(size: 14))
                            .lineLimit(1)
                        
                        Spacer()
                    }
                }
                
                if filteredTasks.count > 5 {
                    Text("+ ещё \(filteredTasks.count - 5)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
    }
}

struct TaskFlowWidgetsEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            // Существующий циферблат для маленького виджета
            WidgetClockView(
                categories: entry.categories,
                currentCategory: entry.currentCategory,
                timeRemaining: 1500, 
                totalTime: 3600
            )
            
        case .systemMedium:
            // Комбинированный вид для среднего виджета
            HStack {
                WidgetClockView(
                    categories: entry.categories,
                    currentCategory: entry.currentCategory,
                    timeRemaining: 1500,
                    totalTime: 3600
                )
                .frame(width: 100, height: 100)
                
                Divider()
                    .background(Color.gray.opacity(0.5))
                
                // Список задач для текущей категории
                VStack(alignment: .leading) {
                    let filteredTasks = entry.tasks.filter { $0.category == entry.currentCategory }
                    
                    Text(entry.currentCategory)
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    if filteredTasks.isEmpty {
                        Text("Нет активных задач")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        ForEach(filteredTasks.prefix(3)) { task in
                            HStack {
                                Circle()
                                    .fill(task.isCompleted ? Color.green : Color.blue)
                                    .frame(width: 8, height: 8)
                                
                                Text(task.title)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding(.leading, 8)
            }
            
        case .systemLarge:
            // Для большого виджета - циферблат + большой список задач
            VStack {
                WidgetClockView(
                    categories: entry.categories,
                    currentCategory: entry.currentCategory,
                    timeRemaining: 1500,
                    totalTime: 3600
                )
                .frame(height: 120)
                .padding(.bottom, 8)
                
                Divider()
                    .background(Color.gray.opacity(0.5))
                    .padding(.horizontal)
                
                // Список задач с полной информацией
                WidgetTaskView(
                    categories: entry.categories,
                    currentCategory: entry.currentCategory,
                    tasks: entry.tasks
                )
            }
            
        default:
            Text("Неподдерживаемый размер виджета")
        }
    }
}

struct TaskFlowWidgets: Widget {
    let kind: String = "TaskFlowWidgets"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            TaskFlowWidgetsEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

// Дополнительный метод для SimpleEntry
extension SimpleEntry {
    static func withSampleTasks(date: Date, configuration: ConfigurationAppIntent) -> SimpleEntry {
        var entry = SimpleEntry(date: date, configuration: configuration)
        entry.tasks = Provider().getSampleTasks()
        return entry
    }
}

// И обновленные превью
#Preview(as: .systemSmall) {
    TaskFlowWidgets()
} timeline: {
    SimpleEntry.withSampleTasks(date: Date.now, configuration: ConfigurationAppIntent.smiley)
}

#Preview(as: .systemMedium) {
    TaskFlowWidgets()
} timeline: {
    SimpleEntry.withSampleTasks(date: Date.now, configuration: ConfigurationAppIntent.smiley)
}

#Preview(as: .systemLarge) {
    TaskFlowWidgets()
} timeline: {
    SimpleEntry.withSampleTasks(date: Date.now, configuration: ConfigurationAppIntent.smiley)
}
