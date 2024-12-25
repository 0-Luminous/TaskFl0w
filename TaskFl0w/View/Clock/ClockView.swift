import SwiftUI


struct ClockView: View {
    @StateObject private var viewModel = ClockViewModel()
    
    @State private var showingAddTask = false
    @State private var showingSettings = false
    @State private var showingCalendar = false
    @State private var showingStatistics = false
    @State private var currentDate = Date()
    @State private var showingTodayTasks = false
    
    // Drag & Drop
    @State private var draggedCategory: TaskCategoryModel?
    
    // Редактирование категорий
    @State private var showingCategoryEditor = false
    @State private var selectedCategory: TaskCategoryModel?
    
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
                        draggedCategory: $draggedCategory,
                        clockFaceColor: currentClockFaceColor
                    )
                }
                
                Spacer()
                
                // Набор категорий снизу
                CategoryDockBar(
                    viewModel: viewModel,
                    showingAddTask: $showingAddTask,
                    draggedCategory: $draggedCategory,
                    showingCategoryEditor: $showingCategoryEditor,
                    selectedCategory: $selectedCategory
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
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gear")
                        }
                        Button(action: { showingStatistics = true }) {
                            Image(systemName: "chart.bar")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingCalendar = true }) {
                            Image(systemName: "calendar")
                        }
                        Button(action: { showingTodayTasks = true }) {
                            Image(systemName: "list.bullet")
                        }
                    }
                }
            }
            // Пример использования листов (sheet)
            .sheet(isPresented: $showingAddTask) {
                TaskEditorView(viewModel: viewModel, isPresented: $showingAddTask)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingCalendar) {
                CalendarView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingStatistics) {
                StatisticsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingTodayTasks) {
                TodayTasksView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingCategoryEditor) {
                // CategoryEditorView, например
                CategoryEditorView(
                    viewModel: viewModel,
                    isPresented: $showingCategoryEditor,
                    clockOffset: .constant(0)
                )
            }
        }
        // Подложка цветом циферблата
        .background(currentClockFaceColor)
        .preferredColorScheme(viewModel.isDarkMode ? .dark : .light)
        .onReceive(timer) { _ in
            // Если выбранная дата совпадает с сегодня, тогда обновляем "currentDate" каждую секунду
            if Calendar.current.isDate(viewModel.selectedDate, inSameDayAs: Date()) {
                currentDate = Date()
            }
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
