//
//  ClockViewIpad.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI


struct ClockViewIpad: View {
    @StateObject private var viewModel = ClockViewModel()
    
    @Environment(\.colorScheme) var colorScheme 
    
    // Таймер для "реал-тайм" обновления
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @AppStorage("lightModeOuterRingColor") private var lightModeOuterRingColor: String = Color.gray.opacity(0.3).toHex()
    @AppStorage("darkModeOuterRingColor") private var darkModeOuterRingColor: String = Color.gray.opacity(0.3).toHex()
    @AppStorage("zeroPosition") private var zeroPosition: Double = 0.0
    
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
    
    private var currentOuterRingColor: Color {
        let hexColor = colorScheme == .dark ? darkModeOuterRingColor : lightModeOuterRingColor
        return Color(hex: hexColor) ?? .gray.opacity(0.3)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                ZStack {
                    // Внешнее кольцо
                    Circle()
                        .stroke(currentOuterRingColor, lineWidth: 22) // Немного тоньше, чем в iOS (20)
                        .frame(
                            width: UIScreen.main.bounds.width * 0.37, // Немного больше самого циферблата
                            height: UIScreen.main.bounds.width * 0.37
                        )
                    
                    // Циферблат часов
                    GlobleClockFaceViewIpad(
                        currentDate: viewModel.selectedDate,
                        tasks: viewModel.tasks,
                        viewModel: viewModel,
                        draggedCategory: $viewModel.draggedCategory,
                        clockFaceColor: currentClockFaceColor,
                        zeroPosition: zeroPosition
                    )
                    .frame(width: UIScreen.main.bounds.width * 0.35, height: UIScreen.main.bounds.width * 0.35)
                }
                
                Spacer()
                
                // Набор категорий снизу
                DockBarForIpad(
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
                            Image(systemName: "sharedwithyou")
                        }
                    }
                }
            }
            // Пример использования листов (sheet)
            .sheet(isPresented: $viewModel.showingAddTask) {
                TaskEditorView(viewModel: viewModel, isPresented: $viewModel.showingAddTask)
            }
            .fullScreenCover(isPresented: $viewModel.showingSettings) {
                SettingsViewIpad()
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
            .fullScreenCover(isPresented: $viewModel.showingCategoryEditor) {
                // CategoryEditorView, например
                CategoryEditorViewIpad(
                    viewModel: viewModel,
                    isPresented: $viewModel.showingCategoryEditor
                )
            }
            .background(colorScheme == .dark ? .black : .white)
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
    }
}

#Preview{
    ClockViewIpad()
}
