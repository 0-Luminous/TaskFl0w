import SwiftUI

struct MainClockFaceView: View {
    let currentDate: Date
    let tasks: [Task]
    @ObservedObject var viewModel: ClockViewModel
    
    @Binding var draggedCategory: TaskCategoryModel?
    let clockFaceColor: Color
    
    // Локальные состояния
    @State private var selectedTask: Task?
    @State private var showingTaskDetail = false
    @State private var dropLocation: CGPoint?
    
    // Режимы редактирования
    @State private var isEditingMode = false
    @State private var editingTask: Task?
    @State private var isDraggingStart = false
    @State private var isDraggingEnd = false
    @State private var previewTime: Date?
    
    // Отфильтрованные задачи под выбранную дату
    private var tasksForSelectedDate: [Task] {
        tasks.filter { Calendar.current.isDate($0.startTime, inSameDayAs: currentDate) }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(clockFaceColor)
                .stroke(Color.gray, lineWidth: 2)
            
            MainTaskArcsView(
                tasks: tasksForSelectedDate,
                viewModel: viewModel,
                selectedTask: $selectedTask,
                showingTaskDetail: $showingTaskDetail,
                isEditingMode: $isEditingMode,
                editingTask: $editingTask,
                isDraggingStart: $isDraggingStart,
                isDraggingEnd: $isDraggingEnd,
                previewTime: $previewTime
            )
            
            MainClockMarksView()
            
            MainClockHandView(currentDate: currentDate)
            
            // Показ точки, куда «кидаем» категорию
            if let location = dropLocation {
                Circle()
                    .fill(draggedCategory?.color ?? .clear)
                    .frame(width: 20, height: 20)
                    .position(location)
            }
            
            // Если редактируем задачу
            if isEditingMode, let time = previewTime, let task = editingTask {
                ClockCenterView(
                    currentDate: time,
                    isDraggingStart: isDraggingStart,
                    isDraggingEnd: isDraggingEnd,
                    task: task
                )
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(height: UIScreen.main.bounds.width * 0.7)
        .padding()
        .animation(.spring(), value: tasksForSelectedDate)
        
        // Drop — создание новой задачи (Drag & Drop категории)
        .onDrop(of: [.text], isTargeted: nil) { providers, location in
            guard let category = draggedCategory else { return false }
            let dropPoint = location
            self.dropLocation = dropPoint
            
            let time = timeForLocation(dropPoint)
            
            // Собираем дату с учётом выбранного дня + времени
            let calendar = Calendar.current
            let selectedComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            
            var newTaskComponents = DateComponents()
            newTaskComponents.year = selectedComponents.year
            newTaskComponents.month = selectedComponents.month
            newTaskComponents.day = selectedComponents.day
            newTaskComponents.hour = timeComponents.hour
            newTaskComponents.minute = timeComponents.minute
            
            let newTaskDate = calendar.date(from: newTaskComponents) ?? time
            
            // Создаём новую задачу
            let newTask = Task(
                id: UUID(),
                title: "Новая задача",
                startTime: newTaskDate,
                duration: 3600, // 1 час
                color: category.color,
                icon: category.iconName,
                category: category,
                isCompleted: false
            )
            
            // Добавляем через viewModel
            viewModel.addTask(newTask)
            
            // Анимация исчезновения точки
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.dropLocation = nil
            }
            
            // Включаем режим редактирования, чтобы пользователь сразу мог двигать границы
            isEditingMode = true
            editingTask = newTask
            
            return true
        }
        .sheet(isPresented: $showingTaskDetail) {
            if let task = selectedTask {
                TaskEditorView(viewModel: viewModel, task: task, isPresented: $showingTaskDetail)
            }
        }
    }
    
    // MARK: - Вспомогательные
    
    private func timeForLocation(_ location: CGPoint) -> Date {
        let center = CGPoint(x: UIScreen.main.bounds.width * 0.35,
                             y: UIScreen.main.bounds.width * 0.35)
        let vector = CGVector(dx: location.x - center.x, dy: location.y - center.y)
        
        var angle = atan2(vector.dy, vector.dx)
        
        // Переводим в градусы
        var degrees = angle * 180 / .pi
        degrees = (degrees - 90 + 360).truncatingRemainder(dividingBy: 360)
        
        // 24 часа = 360 градусов => 1 час = 15 градусов
        let hours = degrees / 15
        let hourComponent = Int(hours)
        let minuteComponent = Int((hours - Double(hourComponent)) * 60)
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: currentDate)
        components.hour = hourComponent
        components.minute = minuteComponent
        
        return Calendar.current.date(from: components) ?? currentDate
    }
}
