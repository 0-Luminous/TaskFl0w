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
    var timeRemaining: TimeInterval = 1500 // По умолчанию 25 минут (1500 секунд)
    var totalTime: TimeInterval = 3600 // По умолчанию 1 час (3600 секунд)
}

// Добавляем механизм получения данных из основного приложения
class WidgetDataProvider {
    // Получить UserDefaults из app group для обмена данными с основным приложением
    static let sharedUserDefaults = UserDefaults(suiteName: "group.AbstractSoft.TaskFl0w")
    
    // Ключи для сохранения данных в UserDefaults
    private struct UserDefaultsKeys {
        static let currentCategory = "widget_current_category"
        static let timeRemaining = "widget_time_remaining"
        static let totalTime = "widget_total_time"
        static let categories = "widget_categories"
        static let tasks = "widget_tasks"
    }
    
    // Получение текущей категории и оставшегося времени из общего UserDefaults
    static func getCurrentCategoryInfo() -> (category: String, timeRemaining: TimeInterval, totalTime: TimeInterval) {
        let defaults = sharedUserDefaults ?? UserDefaults.standard
        
        let category = defaults.string(forKey: UserDefaultsKeys.currentCategory) ?? "Отдых"
        let timeRemaining = defaults.double(forKey: UserDefaultsKeys.timeRemaining)
        let totalTime = defaults.double(forKey: UserDefaultsKeys.totalTime)
        
        // Если не удалось получить данные из UserDefaults или основное приложение не сохранило их,
        // возвращаем фиктивные данные из генератора расписания
        if timeRemaining <= 0 {
            return generateScheduleBasedCategoryInfo()
        }
        
        return (category, timeRemaining, totalTime)
    }
    
    // Получение категорий из основного приложения
    static func getCategories() -> [String] {
        let defaults = sharedUserDefaults ?? UserDefaults.standard
        
        if let categoriesData = defaults.data(forKey: UserDefaultsKeys.categories),
           let categories = try? JSONDecoder().decode([String].self, from: categoriesData) {
            return categories
        }
        
        // Возвращаем значения по умолчанию, если не удалось получить из UserDefaults
        return ["Работа", "Перерыв", "Учеба", "Хобби"]
    }
    
    // Получение задач из основного приложения
    static func getTasks() -> [WidgetTodoTask] {
        let defaults = sharedUserDefaults ?? UserDefaults.standard
        
        if let tasksData = defaults.data(forKey: UserDefaultsKeys.tasks) {
            // Пробуем декодировать как массив словарей
            if let jsonArray = try? JSONSerialization.jsonObject(with: tasksData) as? [[String: Any]] {
                return jsonArray.compactMap { dict -> WidgetTodoTask? in
                    guard 
                        let id = dict["id"] as? String,
                        let title = dict["title"] as? String,
                        let isCompleted = dict["isCompleted"] as? Bool,
                        let category = dict["category"] as? String
                    else {
                        return nil
                    }
                    
                    return WidgetTodoTask(
                        id: id,
                        title: title,
                        isCompleted: isCompleted,
                        category: category
                    )
                }
            }
        }
        
        // Возвращаем тестовые данные, если не удалось получить из UserDefaults
        return getSampleTasks()
    }
    
    // Получение тестовых данных для предпросмотра
    static func getSampleTasks() -> [WidgetTodoTask] {
        return [
            WidgetTodoTask(id: "1", title: "Ответить на письма", isCompleted: false, category: "Работа"),
            WidgetTodoTask(id: "2", title: "Подготовить отчет", isCompleted: false, category: "Работа"),
            WidgetTodoTask(id: "3", title: "Созвон с клиентом", isCompleted: true, category: "Работа"),
            WidgetTodoTask(id: "4", title: "Прочитать главу книги", isCompleted: false, category: "Учеба"),
            WidgetTodoTask(id: "5", title: "Выпить чай", isCompleted: false, category: "Перерыв"),
            WidgetTodoTask(id: "6", title: "Размяться", isCompleted: true, category: "Перерыв")
        ]
    }
    
    // Генерация расписания на текущий день (если нет данных от основного приложения)
    private static func generateScheduleBasedCategoryInfo() -> (category: String, timeRemaining: TimeInterval, totalTime: TimeInterval) {
        let now = Date()
        let calendar = Calendar.current
        var startComponents = calendar.dateComponents([.year, .month, .day], from: now)
        startComponents.hour = 9
        startComponents.minute = 0
        
        var categoryTimes: [(category: String, start: Date, end: Date)] = []
        
        // Рабочий день с 9:00 до 18:00 с перерывами
        if let startTime = calendar.date(from: startComponents) {
            // Работа с 9:00 до 12:00
            let endWork1 = calendar.date(byAdding: .hour, value: 3, to: startTime)!
            categoryTimes.append(("Работа", startTime, endWork1))
            
            // Перерыв с 12:00 до 13:00
            let startBreak = endWork1
            let endBreak = calendar.date(byAdding: .hour, value: 1, to: startBreak)!
            categoryTimes.append(("Перерыв", startBreak, endBreak))
            
            // Работа с 13:00 до 16:00
            let startWork2 = endBreak
            let endWork2 = calendar.date(byAdding: .hour, value: 3, to: startWork2)!
            categoryTimes.append(("Работа", startWork2, endWork2))
            
            // Учеба с 16:00 до 18:00
            let startStudy = endWork2
            let endStudy = calendar.date(byAdding: .hour, value: 2, to: startStudy)!
            categoryTimes.append(("Учеба", startStudy, endStudy))
        }
        
        // Находим текущую активную категорию
        for (category, start, end) in categoryTimes {
            if now >= start && now < end {
                // Нашли текущую категорию, вычисляем оставшееся время
                let timeRemaining = end.timeIntervalSince(now)
                let totalTime = end.timeIntervalSince(start)
                return (category, timeRemaining, totalTime)
            }
        }
        
        // Если активной категории не найдено, возвращаем "Отдых" и 0 секунд
        return ("Отдых", 0, 0)
    }
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        var entry = SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
        
        // Получаем данные для виджета
        entry.tasks = WidgetDataProvider.getTasks()
        entry.categories = WidgetDataProvider.getCategories()
        
        // Получаем текущую категорию и оставшееся время
        let (category, timeRemaining, totalTime) = WidgetDataProvider.getCurrentCategoryInfo()
        entry.currentCategory = category
        entry.timeRemaining = timeRemaining
        entry.totalTime = totalTime
        
        return entry
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        var entry = SimpleEntry(date: Date(), configuration: configuration)
        
        // Получаем данные для виджета
        entry.tasks = WidgetDataProvider.getTasks()
        entry.categories = WidgetDataProvider.getCategories()
        
        // Получаем текущую категорию и оставшееся время
        let (category, timeRemaining, totalTime) = WidgetDataProvider.getCurrentCategoryInfo()
        entry.currentCategory = category
        entry.timeRemaining = timeRemaining
        entry.totalTime = totalTime
        
        return entry
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        
        // Текущая дата и время
        let currentDate = Date()
        
        // Получаем начальные данные
        let tasks = WidgetDataProvider.getTasks()
        let categories = WidgetDataProvider.getCategories()
        let (initialCategory, initialTimeRemaining, initialTotalTime) = WidgetDataProvider.getCurrentCategoryInfo()
        
        // Определяем интервал обновления (минимум 5 минут для экономии ресурсов)
        let updateInterval: TimeInterval = min(initialTimeRemaining, 300)
        
        // Если нет активной категории или времени слишком мало, обновляем каждые 15 минут
        let effectiveUpdateInterval = (updateInterval <= 0) ? 900 : updateInterval
        
        // Создаем записи для обновления виджета
        for minuteOffset in stride(from: 0, to: 60, by: 5) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            var entry = SimpleEntry(date: entryDate, configuration: configuration)
            
            // Устанавливаем задачи и категории
            entry.tasks = tasks
            entry.categories = categories
            
            // Расчет оставшегося времени с учетом смещения
            let adjustedRemaining = max(0, initialTimeRemaining - Double(minuteOffset * 60))
            
            entry.currentCategory = initialCategory
            entry.timeRemaining = adjustedRemaining
            entry.totalTime = initialTotalTime
            
            entries.append(entry)
        }

        // Обновляем виджет каждые 15 минут или перед окончанием текущей категории
        return Timeline(entries: entries, policy: .after(Date().addingTimeInterval(effectiveUpdateInterval)))
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
                // Фоновый круг (серый)
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: size, height: size)
                
                // Прогресс-индикатор (заполняющийся круг)
                Circle()
                    .trim(from: 0, to: CGFloat(1 - (timeRemaining / totalTime)))
                    .stroke(Color.blue, lineWidth: 4)
                    .rotationEffect(.degrees(-90))
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
                    .fill(isActive ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
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
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
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
            // Обновленный циферблат для маленького виджета
            WidgetClockView(
                categories: entry.categories,
                currentCategory: entry.currentCategory,
                timeRemaining: entry.timeRemaining, 
                totalTime: entry.totalTime
            )
            
        case .systemMedium:
            // Комбинированный вид для среднего виджета
            HStack {
                WidgetClockView(
                    categories: entry.categories,
                    currentCategory: entry.currentCategory,
                    timeRemaining: entry.timeRemaining,
                    totalTime: entry.totalTime
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
                    timeRemaining: entry.timeRemaining,
                    totalTime: entry.totalTime
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
        entry.tasks = WidgetDataProvider.getSampleTasks()
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
