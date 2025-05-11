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

// Модернизированный компонент для отображения циферблата
struct EnhancedClockView: View {
    var categories: [String]
    var currentCategory: String
    var timeRemaining: TimeInterval
    var totalTime: TimeInterval
    @Environment(\.colorScheme) var colorScheme
    
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
                // Фоновый круг - упрощенная версия
                Circle()
                    .fill(colorScheme == .dark ? Color.black.opacity(0.7) : Color.gray.opacity(0.1))
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                // Секторы категорий - упрощенная версия
                ForEach(0..<categories.count, id: \.self) { index in
                    let angle = 360.0 / Double(categories.count)
                    let startAngle = Angle(degrees: Double(index) * angle - 90)
                    let endAngle = Angle(degrees: Double(index + 1) * angle - 90)
                    let isActive = categories[index] == currentCategory
                    let categoryColor = colorForCategory(categories[index])
                    
                    SectorView(
                            center: center,
                            radius: radius * 0.8,
                            startAngle: startAngle,
                            endAngle: endAngle,
                        isActive: isActive,
                        categoryColor: categoryColor
                        )
                    
                    // Иконка категории
                        let iconAngle = startAngle.degrees + (endAngle.degrees - startAngle.degrees) / 2
                        let distance = radius * 0.55
                        let iconX = center.x + cos(iconAngle * .pi / 180) * distance
                        let iconY = center.y + sin(iconAngle * .pi / 180) * distance
                        
                    CategoryIconView(
                        category: categories[index],
                        isActive: isActive,
                        categoryColor: categoryColor,
                        size: size * 0.08,
                        position: CGPoint(x: iconX, y: iconY)
                    )
                }
                
                // Прогресс-индикатор
                if totalTime > 0 {
                    let progress = 1 - (timeRemaining / totalTime)
                    ProgressRingView(
                        progress: progress,
                        categoryColor: colorForCategory(currentCategory),
                        size: size * 0.85
                    )
                }
                
                // Внутренний круг
                InnerCircleView(size: size * 0.65)
                
                // Текст времени и категории
                TimeAndCategoryView(
                    timeRemaining: timeRemaining,
                    category: currentCategory,
                    categoryColor: colorForCategory(currentCategory),
                    size: size,
                    isDarkMode: colorScheme == .dark
                )
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    // Определение иконки по названию категории
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Работа": return "briefcase.fill"
        case "Перерыв": return "cup.and.saucer.fill"
        case "Учеба": return "book.fill"
        case "Хобби": return "paintpalette.fill"
        case "Отдых": return "house.fill"
        case "Спорт": return "figure.run"
        case "Встречи": return "person.2.fill"
        case "Питание": return "fork.knife"
        case "Созвоны": return "phone.fill"
        default: return "clock.fill"
        }
    }
    
    // Если в EnhancedClockView есть отдельный метод formatTime
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else {
            return String(format: "%d мин", minutes)
        }
    }
}

// Вспомогательное представление для сектора
struct SectorView: View {
    let center: CGPoint
    let radius: CGFloat
    let startAngle: Angle
    let endAngle: Angle
    let isActive: Bool
    let categoryColor: Color
    
    var body: some View {
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
        .fill(isActive ? categoryColor.opacity(0.6) : Color.gray.opacity(0.15))
        .shadow(color: isActive ? categoryColor.opacity(0.4) : .clear, radius: isActive ? 3 : 0, x: 0, y: 0)
    }
}

// Вспомогательное представление для иконки категории
struct CategoryIconView: View {
    let category: String
    let isActive: Bool
    let categoryColor: Color
    let size: CGFloat
    let position: CGPoint
    
    var iconName: String {
        switch category {
        case "Работа": return "briefcase.fill"
        case "Перерыв": return "cup.and.saucer.fill"
        case "Учеба": return "book.fill"
        case "Хобби": return "paintpalette.fill"
        case "Отдых": return "house.fill"
        case "Спорт": return "figure.run"
        case "Встречи": return "person.2.fill"
        case "Питание": return "fork.knife"
        case "Созвоны": return "phone.fill"
        default: return "clock.fill"
        }
    }
    
    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: size, weight: isActive ? .bold : .regular))
            .foregroundColor(isActive ? .white : .gray.opacity(0.6))
            .opacity(isActive ? 1.0 : 0.5)
            .position(x: position.x, y: position.y)
    }
}

// Вспомогательное представление для кольца прогресса
struct ProgressRingView: View {
    let progress: Double
    let categoryColor: Color
    let size: CGFloat
    
    var body: some View {
        Circle()
            .trim(from: 0, to: CGFloat(progress))
            .stroke(categoryColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .frame(width: size, height: size)
    }
}

// Вспомогательное представление для внутреннего круга
struct InnerCircleView: View {
    let size: CGFloat
    
    var body: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
            )
    }
}

// Вспомогательное представление для времени и категории
struct TimeAndCategoryView: View {
    let timeRemaining: TimeInterval
    let category: String
    let categoryColor: Color
    let size: CGFloat
    let isDarkMode: Bool
    
    // Форматирование времени в читаемый вид без секунд
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else {
            return String(format: "%d мин", minutes)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(formatTime(timeRemaining))
                .font(.system(size: size * 0.20, weight: .bold, design: .rounded))
                .foregroundColor(isDarkMode ? .white : .black.opacity(0.8))
            
            Text(category)
                .font(.system(size: size * 0.09, weight: .medium, design: .rounded))
                .foregroundColor(categoryColor)
        }
        .frame(width: size * 0.6)
    }
}

// Улучшенное представление задач
struct EnhancedTaskView: View {
    var currentCategory: String
    var tasks: [WidgetTodoTask]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Заголовок с категорией
            HStack(spacing: 8) {
                Image(systemName: iconForCategory(currentCategory))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(CategoryColorProvider.getColorFor(category: currentCategory))
                
            Text(currentCategory)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(CategoryColorProvider.getColorFor(category: currentCategory))
                
                Spacer()
                
                // Добавляем счетчик выполненных задач
                let completedCount = tasks.filter { $0.category == currentCategory && $0.isCompleted }.count
                let totalCount = tasks.filter { $0.category == currentCategory }.count
                
                if totalCount > 0 {
                    Text("\(completedCount)/\(totalCount)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.5))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(
                                            Color.gray.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                        )
                }
            }
            .padding(.bottom, 6)
            
            let filteredTasks = tasks.filter { $0.category == currentCategory }
            
            if filteredTasks.isEmpty {
                // Улучшенное сообщение при отсутствии задач
                HStack {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(CategoryColorProvider.getColorFor(category: currentCategory).opacity(0.6))
                    
                    Text("Все задачи выполнены")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.gray.opacity(0.8))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
            } else {
                // Список задач с усовершенствованным дизайном
                ForEach(Array(filteredTasks.prefix(5).enumerated()), id: \.element.id) { index, task in
                    HStack(spacing: 12) {
                        // Улучшенный индикатор задачи с эффектом нажатия
                        ZStack {
                            Circle()
                                .fill(task.isCompleted ? 
                                      Color.green0.opacity(0.3) : 
                                      CategoryColorProvider.getColorFor(category: currentCategory).opacity(0.2))
                                .frame(width: 24, height: 24)
                            
                            Circle()
                                .strokeBorder(
                                    task.isCompleted ? 
                                    Color.green0 : 
                                    CategoryColorProvider.getColorFor(category: currentCategory),
                                    lineWidth: 1.5
                                )
                                .frame(width: 24, height: 24)
                            
                            if task.isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.green0)
                            }
                        }
                        .shadow(
                            color: task.isCompleted ? 
                            Color.green0.opacity(0.3) : 
                            CategoryColorProvider.getColorFor(category: currentCategory).opacity(0.3),
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                        
                        Text(task.title)
                            .font(.system(size: 14, weight: task.isCompleted ? .regular : .medium, design: .rounded))
                            .foregroundColor(task.isCompleted ? .gray : (colorScheme == .dark ? .white : .black))
                            .lineLimit(1)
                            .strikethrough(task.isCompleted)
                            .opacity(task.isCompleted ? 0.7 : 1.0)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                colorScheme == .dark ? 
                                Color.black.opacity(0.2) : 
                                Color.white.opacity(0.7)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        Color.gray.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.05),
                        radius: 2,
                        x: 0,
                        y: 1
                    )
                    .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.05), value: filteredTasks.count)
                }
                
                if filteredTasks.count > 5 {
                    HStack {
                        Spacer()
                        Text("+ ещё \(filteredTasks.count - 5)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(
                                Capsule()
                                    .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.5))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .padding(.top, 6)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    // Определение иконки по названию категории
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Работа": return "briefcase.fill"
        case "Перерыв": return "cup.and.saucer.fill"
        case "Учеба": return "book.fill"
        case "Хобби": return "paintpalette.fill"
        case "Отдых": return "house.fill"
        case "Спорт": return "figure.run"
        case "Встречи": return "person.2.fill"
        case "Питание": return "fork.knife"
        case "Созвоны": return "phone.fill"
        default: return "clock.fill"
        }
    }
}

struct TaskFlowWidgetsEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Улучшенный фон для всех виджетов
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
                .padding(10)
                
            case .systemMedium:
                // Комбинированный вид для среднего виджета с улучшенным дизайном
                HStack(spacing: 10) {
                    // Левая часть с циферблатом
                    EnhancedClockView(
                        categories: entry.categories,
                        currentCategory: entry.currentCategory,
                        timeRemaining: entry.timeRemaining,
                        totalTime: entry.totalTime
                    )
                    .frame(width: 140, height: 140)
                    .padding(.leading, 10)
                    
                    // Разделитель с градиентом
                    Rectangle()
                        .fill(
                            .linearGradient(
                                colors: [
                                    .clear,
                                    CategoryColorProvider.getColorFor(category: entry.currentCategory).opacity(0.3),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1)
                        .padding(.vertical, 20)
                    
                    // Правая часть с задачами и улучшенным отображением
                    VStack(alignment: .leading, spacing: 8) {
                        let filteredTasks = entry.tasks.filter { $0.category == entry.currentCategory }
                        
                        // Заголовок с иконкой
                        HStack(spacing: 6) {
                            Image(systemName: iconForCategory(entry.currentCategory))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(CategoryColorProvider.getColorFor(category: entry.currentCategory))
                            
                        Text(entry.currentCategory)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(CategoryColorProvider.getColorFor(category: entry.currentCategory))
                        }
                            .padding(.bottom, 4)
                        
                        if filteredTasks.isEmpty {
                            // Сообщение об отсутствии задач
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(CategoryColorProvider.getColorFor(category: entry.currentCategory).opacity(0.6))
                                Text("Задачи выполнены")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.gray)
                            }
                                .padding(.vertical, 8)
                        } else {
                            // Список задач с улучшенным дизайном
                            ForEach(filteredTasks.prefix(3)) { task in
                                HStack(spacing: 8) {
                                    // Улучшенный индикатор выполнения
                                    ZStack {
                                    Circle()
                                            .fill(task.isCompleted ? Color.green0.opacity(0.2) : Color.clear)
                                            .frame(width: 18, height: 18)
                                        
                                            Circle()
                                                .strokeBorder(
                                                    task.isCompleted ? Color.green0 : CategoryColorProvider.getColorFor(category: entry.currentCategory),
                                                    lineWidth: 1.5
                                                )
                                            .frame(width: 18, height: 18)
                                        
                                        if task.isCompleted {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(Color.green0)
                                        }
                                    }
                                    
                                    Text(task.title)
                                        .font(.system(size: 14, weight: task.isCompleted ? .regular : .medium, design: .rounded))
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .lineLimit(1)
                                        .strikethrough(task.isCompleted)
                                        .opacity(task.isCompleted ? 0.7 : 1.0)
                                }
                                .padding(.vertical, 5)
                            }
                            
                            if filteredTasks.count > 3 {
                                Text("+ ещё \(filteredTasks.count - 3)")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.gray)
                                    .padding(.top, 2)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
            case .systemLarge:
                // Для большого виджета - улучшенный дизайн с нейморфизмом
                VStack(spacing: 12) {
                    // Циферблат на верху
                    EnhancedClockView(
                        categories: entry.categories,
                        currentCategory: entry.currentCategory,
                        timeRemaining: entry.timeRemaining,
                        totalTime: entry.totalTime
                    )
                    .frame(height: 180)
                    .padding(.top, 12)
                    
                    // Улучшенный разделитель с градиентом
                    Rectangle()
                        .fill(
                            .linearGradient(
                                colors: [
                                    .clear,
                                    CategoryColorProvider.getColorFor(category: entry.currentCategory).opacity(0.5),
                                    .clear
                                ],
                                startPoint: .leading, 
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                        .padding(.horizontal, 40)
                    
                    // Улучшенный список задач
                    EnhancedTaskView(
                        currentCategory: entry.currentCategory,
                        tasks: entry.tasks
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                
            default:
                Text("Неподдерживаемый размер виджета")
                    .font(.system(size: 14, design: .rounded))
            }
        }
    }
    
    // Улучшенный градиентный фон для виджетов с акцентами
    private var backgroundView: some View {
        let categoryColor = CategoryColorProvider.getColorFor(category: entry.currentCategory)
        
        return ZStack {
            // Основной градиент
            LinearGradient(
            gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(red: 0.12, green: 0.12, blue: 0.12) : Color(red: 0.95, green: 0.95, blue: 0.97),
                    colorScheme == .dark ? Color(red: 0.07, green: 0.07, blue: 0.08) : Color(red: 0.90, green: 0.90, blue: 0.92)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
            
            // Динамические акцентные элементы
            GeometryReader { geometry in
                // Верхний левый акцент
                Circle()
                    .fill(categoryColor.opacity(colorScheme == .dark ? 0.15 : 0.10))
                    .blur(radius: 20)
                    .frame(width: geometry.size.width * 0.4, height: geometry.size.width * 0.4)
                    .position(x: geometry.size.width * 0.15, y: geometry.size.height * 0.15)
                
                // Нижний правый акцент
                Circle()
                    .fill(categoryColor.opacity(colorScheme == .dark ? 0.12 : 0.08))
                    .blur(radius: 25)
                    .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5)
                    .position(x: geometry.size.width * 0.85, y: geometry.size.height * 0.85)
            }
            
            // Сетка для глубины
            if colorScheme == .dark {
                Image(systemName: "grid")
                    .resizable(resizingMode: .tile)
                    .foregroundColor(.white.opacity(0.03))
                    .blendMode(.overlay)
            }
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
        case "Спорт": return "figure.run"
        case "Встречи": return "person.2.fill"
        case "Питание": return "fork.knife"
        case "Созвоны": return "phone.fill"
        default: return "clock.fill"
        }
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
