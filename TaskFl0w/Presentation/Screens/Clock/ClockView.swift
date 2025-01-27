//
//  ClockView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI


struct ClockView: View {
    @StateObject private var viewModel = ClockViewModel()
    
    @Environment(\.colorScheme) var colorScheme
    
    // Таймер для "реал-тайм" обновления
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                ZStack {
                    // Темное внешнее кольцо
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                        .frame(
                            width: UIScreen.main.bounds.width * 0.8,
                            height: UIScreen.main.bounds.width * 0.8
                        )
                    
                    // Маркеры часов (24 шт.)
                    ForEach(0..<24) { hour in
                        MainClockMarker(hour: hour)
                    }
                    
                    // Сам циферблат (Arcs, Markers, Hand, и Drop)
                    MainClockFaceView(
                        currentDate: viewModel.selectedDate,
                        tasks: viewModel.tasks,
                        viewModel: viewModel,
                        draggedCategory: $viewModel.draggedCategory,
                        clockFaceColor: currentClockFaceColor
                    )
                }
                
                Spacer()
                
                // Набор категорий снизу
                CategoryDockBar(
                    viewModel: viewModel,
                    showingAddTask: $viewModel.showingAddTask,
                    draggedCategory: $viewModel.draggedCategory,
                    showingCategoryEditor: $viewModel.showingCategoryEditor,
                    selectedCategory: $viewModel.selectedCategory
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(formattedDate)
                            .font(.headline)
                        Text(formattedWeekday)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button(action: { viewModel.showingSettings = true }) {
                            Image(systemName: "gear")
                        }
                        Button(action: { viewModel.showingStatistics = true }) {
                            Image(systemName: "chart.bar")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { viewModel.showingCalendar = true }) {
                            Image(systemName: "calendar")
                        }
                        Button(action: { viewModel.showingTodayTasks = true }) {
                            Image(systemName: "list.bullet")
                        }
                    }
                }
            }
            // Пример использования листов (sheet)
            .sheet(isPresented: $viewModel.showingAddTask) {
                TaskEditorView(viewModel: viewModel, isPresented: $viewModel.showingAddTask)
            }
            .sheet(isPresented: $viewModel.showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $viewModel.showingCalendar) {
                CalendarView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingStatistics) {
                StatisticsView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingTodayTasks) {
                TodayTasksView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingCategoryEditor) {
                // CategoryEditorView, например
                CategoryEditorView(
                    viewModel: viewModel,
                    isPresented: $viewModel.showingCategoryEditor
                )
            }
        }
        // Подложка цветом циферблата
        .background(currentClockFaceColor)
        .preferredColorScheme(viewModel.isDarkMode ? .dark : .light)
        .onReceive(timer) { _ in
            // Если выбранная дата совпадает с сегодня, тогда обновляем "currentDate" каждую секунду
            if Calendar.current.isDate(viewModel.selectedDate, inSameDayAs: Date()) {
                viewModel.currentDate = Date()
            }
        }
        .onDrop(of: [.text], isTargeted: nil) { providers, location in
            if let task = viewModel.draggedTask {
                viewModel.taskManagement.removeTask(task)
            }
            return true
        }
    }
    
    // MARK: - Вспомогательные вычислимые свойства
    
    private var currentClockFaceColor: Color {
        let hexColor = colorScheme == .dark
            ? viewModel.darkModeClockFaceColor
            : viewModel.lightModeClockFaceColor
        return Color(hex: hexColor) ?? .white
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: viewModel.selectedDate)
    }
    
    private var formattedWeekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: viewModel.selectedDate).capitalized
    }
}

#Preview{
    ClockView()
}
