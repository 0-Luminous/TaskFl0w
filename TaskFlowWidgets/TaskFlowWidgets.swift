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

// Улучшенный компонент для отображения циферблата
struct EnhancedClockView: View {
    var categories: [String]
    var currentCategory: String
    var timeRemaining: TimeInterval
    var totalTime: TimeInterval
    
    // Функция для получения цвета категории
    private func colorForCategory(_ category: String) -> Color {
        CategoryColorProvider.getColorFor(category: category)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: size/2, y: size/2)
            let radius = size/2 - 8
            
            ZStack {
                // Фоновый круг с градиентом
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.9)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 2)
                
                // Секторы категорий
                ForEach(0..<categories.count, id: \.self) { index in
                    let angle = 360.0 / Double(categories.count)
                    let startAngle = Angle(degrees: Double(index) * angle - 90)
                    let endAngle = Angle(degrees: Double(index + 1) * angle - 90)
                    let isActive = categories[index] == currentCategory
                    let categoryColor = colorForCategory(categories[index])
                    
                    Path { path in
                        path.move(to: center)
                        path.addArc(
                            center: center,
                            radius: radius * 0.8,
                            startAngle: startAngle,
                            endAngle: endAngle,
                            clockwise: false
                        )
                        path.closeSubpath()
                    }
                    .fill(isActive ? categoryColor.opacity(0.5) : Color.gray.opacity(0.15))
                    
                    // Добавляем иконку категории, если активна
                    if isActive {
                        let iconAngle = startAngle.degrees + (endAngle.degrees - startAngle.degrees) / 2
                        let distance = radius * 0.55
                        let iconX = center.x + cos(iconAngle * .pi / 180) * distance
                        let iconY = center.y + sin(iconAngle * .pi / 180) * distance
                        
                        Image(systemName: iconForCategory(categories[index]))
                            .font(.system(size: size * 0.08))
                            .foregroundColor(.white)
                            .position(x: iconX, y: iconY)
                    }
                }
                
                // Прогресс-индикатор (заполняющийся круг)
                if totalTime > 0 {
                    let progress = 1 - (timeRemaining / totalTime)
                    let categoryColor = colorForCategory(currentCategory)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(categoryColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: size * 0.85, height: size * 0.85)
                }
                
                // Внутренний круг для текста с эффектом стекла
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: size * 0.65, height: size * 0.65)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.5), Color.clear]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .blur(radius: 0.5)
                
                // Текст с оставшимся временем
                VStack(spacing: 6) {
                    Text(formatTime(timeRemaining))
                        .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(currentCategory)
                        .font(.system(size: size * 0.09, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(width: size * 0.6)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    // Форматирование времени в читаемый вид
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else {
            return String(format: "%d мин", minutes)
        }
    }
    
    // Определение иконки по названию категории
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Работа": return "briefcase.fill"
        case "Перерыв": return "cup.and.saucer.fill"
        case "Учеба": return "book.fill"
        case "Хобби": return "paintpalette.fill"
        case "Отдых": return "house.fill"
        default: return "clock.fill"
        }
    }
}

struct EnhancedTaskView: View {
    var currentCategory: String
    var tasks: [WidgetTodoTask]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Заголовок с категорией
            Text(currentCategory)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(CategoryColorProvider.getColorFor(category: currentCategory))
                .padding(.bottom, 2)
            
            let filteredTasks = tasks.filter { $0.category == currentCategory }
            
            if filteredTasks.isEmpty {
                // Улучшенное сообщение при отсутствии задач
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.gray.opacity(0.6))
                    Text("Нет активных задач")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.gray.opacity(0.8))
                }
                .padding(.vertical, 6)
            } else {
                // Список задач с анимированным появлением
                ForEach(Array(filteredTasks.prefix(5).enumerated()), id: \.element.id) { index, task in
                    HStack {
                        // Улучшенный индикатор задачи
                        ZStack {
                            Circle()
                                .fill(task.isCompleted ? Color.green0.opacity(0.2) : CategoryColorProvider.getColorFor(category: currentCategory).opacity(0.2))
                                .frame(width: 22, height: 22)
                            
                            Circle()
                                .strokeBorder(task.isCompleted ? Color.green0 : CategoryColorProvider.getColorFor(category: currentCategory), lineWidth: 1.5)
                                .frame(width: 22, height: 22)
                            
                            if task.isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color.green0)
                            }
                        }
                        
                        Text(task.title)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .strikethrough(task.isCompleted)
                            .opacity(task.isCompleted ? 0.7 : 1.0)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .animation(.easeInOut(duration: 0.2).delay(Double(index) * 0.05), value: filteredTasks.count)
                }
                
                if filteredTasks.count > 5 {
                    HStack {
                        Spacer()
                        Text("+ ещё \(filteredTasks.count - 5)")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

struct TaskFlowWidgetsEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Добавляем единый фон для всех виджетов
            backgroundView
            
            switch family {
            case .systemSmall:
                // Улучшенный циферблат для маленького виджета
                EnhancedClockView(
                    categories: entry.categories,
                    currentCategory: entry.currentCategory,
                    timeRemaining: entry.timeRemaining, 
                    totalTime: entry.totalTime
                )
                .padding(8)
                
            case .systemMedium:
                // Комбинированный вид для среднего виджета
                HStack(spacing: 0) {
                    // Левая часть с циферблатом
                    EnhancedClockView(
                        categories: entry.categories,
                        currentCategory: entry.currentCategory,
                        timeRemaining: entry.timeRemaining,
                        totalTime: entry.totalTime
                    )
                    .frame(width: 140, height: 140)
                    .padding(.leading, 8)
                    
                    // Правая часть с задачами
                    VStack(alignment: .leading) {
                        let filteredTasks = entry.tasks.filter { $0.category == entry.currentCategory }
                        
                        // Заголовок
                        Text(entry.currentCategory)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(CategoryColorProvider.getColorFor(category: entry.currentCategory))
                            .padding(.bottom, 4)
                        
                        if filteredTasks.isEmpty {
                            // Сообщение об отсутствии задач
                            Text("Нет активных задач")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.gray)
                                .padding(.vertical, 8)
                        } else {
                            // Список задач
                            ForEach(filteredTasks.prefix(3)) { task in
                                HStack(spacing: 8) {
                                    // Индикатор выполнения
                                    Circle()
                                        .fill(task.isCompleted ? Color.green0 : .clear)
                                        .frame(width: 12, height: 12)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(
                                                    task.isCompleted ? Color.green0 : CategoryColorProvider.getColorFor(category: entry.currentCategory),
                                                    lineWidth: 1.5
                                                )
                                        )
                                    
                                    Text(task.title)
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .strikethrough(task.isCompleted)
                                        .opacity(task.isCompleted ? 0.7 : 1.0)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 12)
                    .padding(.vertical, 12)
                }
                
            case .systemLarge:
                // Для большого виджета - улучшенный вид
                VStack(spacing: 10) {
                    // Циферблат на верху
                    EnhancedClockView(
                        categories: entry.categories,
                        currentCategory: entry.currentCategory,
                        timeRemaining: entry.timeRemaining,
                        totalTime: entry.totalTime
                    )
                    .frame(height: 180)
                    .padding(.top, 10)
                    
                    Divider()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .gray.opacity(0.5), .clear]), 
                                startPoint: .leading, 
                                endPoint: .trailing
                            )
                        )
                        .padding(.horizontal, 30)
                    
                    // Список задач внизу
                    EnhancedTaskView(
                        currentCategory: entry.currentCategory,
                        tasks: entry.tasks
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                }
                
            default:
                Text("Неподдерживаемый размер виджета")
                    .font(.system(size: 14, design: .rounded))
            }
        }
    }
    
    // Градиентный фон для виджетов
    private var backgroundView: some View {
        let categoryColor = CategoryColorProvider.getColorFor(category: entry.currentCategory)
        
        return LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color.black : Color(red: 0.1, green: 0.1, blue: 0.1),
                colorScheme == .dark ? Color.black.opacity(0.8) : Color(red: 0.15, green: 0.15, blue: 0.15)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            // Subtle category color accent in the background
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    categoryColor.opacity(colorScheme == .dark ? 0.1 : 0.08)
                )
        )
    }
}

struct TaskFlowWidgets: Widget {
    let kind: String = "TaskFlowWidgets"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            TaskFlowWidgetsEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
    }
}

// Настройки для предпросмотра
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

// Предпросмотры
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
