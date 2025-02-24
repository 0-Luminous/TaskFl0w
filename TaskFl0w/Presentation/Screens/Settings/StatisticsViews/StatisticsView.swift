//
//  StatisticsView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI
import Charts

struct StatisticsView: View {
    @ObservedObject var viewModel: ClockViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Основные метрики
    
    private var totalTasks: Int {
        viewModel.tasks.count
    }
    
    private var totalDuration: TimeInterval {
        viewModel.tasks.reduce(0) { $0 + $1.duration }
    }
    
    private var averageTaskDuration: TimeInterval {
        totalTasks > 0 ? totalDuration / Double(totalTasks) : 0
    }
    
    private var completedTasks: Int {
        viewModel.tasks.filter { Calendar.current.compare($0.endTime, to: Date(), toGranularity: .minute) == .orderedAscending }.count
    }
    
    private var completionRate: Double {
        totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) * 100 : 0
    }
    
    // MARK: - Статистика по длительности
    
    private var tasksByDuration: [(type: String, count: Int, color: Color)] {
        let shortTasks = viewModel.tasks.filter { $0.duration <= 3600 }.count // до 1 часа
        let mediumTasks = viewModel.tasks.filter { $0.duration > 3600 && $0.duration <= 7200 }.count // 1-2 часа
        let longTasks = viewModel.tasks.filter { $0.duration > 7200 }.count // более 2 часов
        
        return [
            (type: "До 1 часа", count: shortTasks, color: .green),
            (type: "1-2 часа", count: mediumTasks, color: .orange),
            (type: "Более 2 часов", count: longTasks, color: .red)
        ]
    }
    
    // MARK: - Статистика по времени
    
    private var tasksByHour: [(hour: Int, count: Int)] {
        let hours = viewModel.tasks.map { Calendar.current.component(.hour, from: $0.startTime) }
        return (0...23).map { hour in
            (hour: hour, count: hours.filter { $0 == hour }.count)
        }
    }
    
    private var tasksByWeekday: [(weekday: String, count: Int)] {
        let calendar = Calendar.current
        let weekdays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
        let tasksWeekdays = viewModel.tasks.map { 
            calendar.component(.weekday, from: $0.startTime)
        }
        
        return (1...7).map { weekdayNum in
            let adjustedWeekday = weekdayNum == 1 ? 7 : weekdayNum - 1
            let count = tasksWeekdays.filter { 
                ($0 == 1 ? 7 : $0 - 1) == adjustedWeekday 
            }.count
            return (weekday: weekdays[adjustedWeekday - 1], count: count)
        }
    }
    
    // MARK: - Статистика по категориям
    
    private var tasksByCategory: [(category: String, count: Int, color: Color)] {
        let grouped = Dictionary(grouping: viewModel.tasks) { $0.category }
        return grouped.map { category, tasks in
            (
                category: category.rawValue,
                count: tasks.count,
                color: category.color
            )
        }.sorted { $0.count > $1.count }
    }
    
    private var mostProductiveCategory: (name: String, duration: TimeInterval)? {
        let grouped = Dictionary(grouping: viewModel.tasks) { $0.category }
        let categoryDurations = grouped.mapValues { tasks in
            tasks.reduce(0) { $0 + $1.duration }
        }
        return categoryDurations.max(by: { $0.value < $1.value })
            .map { ($0.key.rawValue, $0.value) }
    }
    
    private var categoryCompletionRates: [(category: String, rate: Double, color: Color)] {
        let grouped = Dictionary(grouping: viewModel.tasks) { $0.category }
        return grouped.map { category, tasks in
            let total = tasks.count
            let completed = tasks.filter { 
                Calendar.current.compare($0.endTime, to: Date(), toGranularity: .minute) == .orderedAscending 
            }.count
            let rate = total > 0 ? Double(completed) / Double(total) * 100 : 0
            return (
                category: category.rawValue,
                rate: rate,
                color: category.color
            )
        }.sorted { $0.rate > $1.rate }
    }
    
    // MARK: - Форматирование
    
    private func formatDuration(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        
        if hours > 0 {
            return String(format: "%dч %02dмин", hours, minutes)
        } else {
            return String(format: "%d мин", minutes)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Основные метрики
                    VStack(spacing: 15) {
                        StatCard(
                            title: "Всего задач",
                            value: "\(totalTasks)",
                            icon: "checklist"
                        )
                        
                        StatCard(
                            title: "Выполнено задач",
                            value: "\(completedTasks) (\(String(format: "%.1f", completionRate))%)",
                            icon: "checkmark.circle"
                        )
                        
                        StatCard(
                            title: "Общая продолжительность",
                            value: formatDuration(totalDuration),
                            icon: "clock"
                        )
                        
                        StatCard(
                            title: "Средняя продолжительность",
                            value: formatDuration(averageTaskDuration),
                            icon: "chart.bar"
                        )
                        
                        if let productive = mostProductiveCategory {
                            StatCard(
                                title: "Самая продуктивная категория",
                                value: "\(productive.name)\n\(formatDuration(productive.duration))",
                                icon: "star"
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Распределение по длительности
                    ChartSection(title: "Распределение по длительности") {
                        Chart(tasksByDuration, id: \.type) { item in
                            SectorMark(
                                angle: .value("Количество", item.count),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .foregroundStyle(item.color)
                            .annotation(position: .overlay) {
                                VStack {
                                    Text("\(item.count)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    Text(item.type)
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                    }
                    
                    // График распределения по дням недели
                    ChartSection(title: "Распределение по дням недели") {
                        Chart(tasksByWeekday, id: \.weekday) { item in
                            BarMark(
                                x: .value("День", item.weekday),
                                y: .value("Количество", item.count)
                            )
                            .foregroundStyle(Color.green.gradient)
                        }
                    }
                    
                    // График распределения по часам
                    ChartSection(title: "Распределение по часам") {
                        Chart(tasksByHour, id: \.hour) { item in
                            BarMark(
                                x: .value("Час", String(format: "%02d:00", item.hour)),
                                y: .value("Количество", item.count)
                            )
                            .foregroundStyle(Color.blue.gradient)
                        }
                    }
                    
                    // Распределение по категориям
                    ChartSection(title: "Топ категорий") {
                        Chart(tasksByCategory.prefix(5), id: \.category) { item in
                            SectorMark(
                                angle: .value("Количество", item.count),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .foregroundStyle(item.color)
                            .annotation(position: .overlay) {
                                VStack {
                                    Text("\(item.count)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    Text(item.category)
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                    }
                    
                    // Процент выполнения по категориям
                    ChartSection(title: "Выполнение по категориям") {
                        Chart(categoryCompletionRates.prefix(5), id: \.category) { item in
                            BarMark(
                                x: .value("Категория", item.category),
                                y: .value("Процент", item.rate)
                            )
                            .foregroundStyle(item.color.gradient)
                            .annotation(position: .overlay) {
                                Text(String(format: "%.0f%%", item.rate))
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Статистика")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Вспомогательные представления

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ChartSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            content()
                .frame(height: 200)
                .padding()
        }
    }
}
