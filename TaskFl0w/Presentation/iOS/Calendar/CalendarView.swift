//
//  CalendarView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel: ClockViewModel
    @StateObject private var listViewModel = ListViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var temporaryDate: Date // Временная дата для хранения выбора
    @State private var selectedMode: BottomBarCalendar.ViewMode = .week
    @State private var tasksForSelectedDate: [TaskOnRing] = []
    @State private var tasksByCategory: [TaskCategoryModel: [TaskOnRing]] = [:]
    @State private var showAddTaskForm = false
    
    init(viewModel: ClockViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        // Инициализируем временную дату текущей выбранной датой
        _temporaryDate = State(initialValue: viewModel.selectedDate)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Секция календаря с синим фоном
                        ZStack {
                            // Синий фон
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.blue)
                                .edgesIgnoringSafeArea(.top)
                            
                            VStack(spacing: 10) { 
                                // Календарь
                                DatePicker("", selection: $temporaryDate, displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .padding()
                                    .background(Color.black.opacity(0.5))
                                    .cornerRadius(20)
                                    .padding(.horizontal)
                                    .colorScheme(.dark) // Принудительно тёмная схема для календаря
                                    .padding(.bottom, 20)
                            }
                            .padding(.top, 120)
                        }
                        
                        // Секция обычных задач из ToDoList
                        TasksFromToDoListView(
                            listViewModel: listViewModel, 
                            selectedDate: temporaryDate,
                            categoryManager: viewModel.categoryManagement
                        )
                        .padding(.horizontal)
                        
                        // Секция задач на циферблате, сгруппированных по категориям
                        if !tasksForSelectedDate.isEmpty {
                            Text("Задачи на циферблате")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                .padding(.top, 10)
                            
                            ForEach(Array(tasksByCategory.keys), id: \.id) { category in
                                if let tasks = tasksByCategory[category], !tasks.isEmpty {
                                    CategoryTasksView(category: category, tasks: tasks)
                                        .padding(.horizontal)
                                }
                            }
                        } else {
                            Text("Нет задач на циферблате")
                                .foregroundColor(.gray)
                                .padding(.top, 20)
                        }
                    }
                    .padding(.bottom, 100) // Увеличиваем отступ для BottomBar
                }
                .background(Color(red: 0.098, green: 0.098, blue: 0.098))
                .edgesIgnoringSafeArea(.top)
                
                VStack {
                    Spacer()
                    BottomBarCalendar(selectedMode: $selectedMode) {
                        // Действие при нажатии на кнопку добавления
                        showAddTaskForm = true
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Календарь")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                            Text("Назад")
                        }
                        .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Применяем выбранную дату и выполняем все необходимые обновления
                        viewModel.selectedDate = temporaryDate
                        
                        // Обновляем UI циферблата
                        viewModel.objectWillChange.send()
                        
                        // Фильтруем задачи на выбранную дату
                        viewModel.tasks = viewModel.sharedState.tasks.filter { task in
                            Calendar.current.isDate(task.startTime, inSameDayAs: temporaryDate)
                        }
                        
                        // Обновляем также состояние clockState
                        viewModel.clockState.selectedDate = temporaryDate
                        viewModel.updateMarkersViewModel()
                        
                        // Закрываем календарь
                        dismiss()
                    }) {
                        Text("Готово")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onChange(of: selectedMode) { newMode in
            // Здесь можно добавить логику при изменении режима отображения
            print("Выбран режим: \(newMode.rawValue)")
        }
        .onChange(of: temporaryDate) { newDate in
            // Обновляем список задач при изменении выбранной даты
            updateTasksForSelectedDate()
        }
        .onAppear {
            // Обновляем список задач при первом появлении
            updateTasksForSelectedDate()
            listViewModel.refreshData() // Загружаем задачи из ToDo
        }
        .sheet(isPresented: $showAddTaskForm) {
            // Показываем форму добавления новой задачи
            NewTaskFormView(viewModel: listViewModel, isPresented: $showAddTaskForm, selectedDate: temporaryDate)
        }
    }
    
    // Метод для обновления списка задач на выбранную дату
    private func updateTasksForSelectedDate() {
        // Фильтруем задачи на выбранный день
        tasksForSelectedDate = viewModel.sharedState.tasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: temporaryDate)
        }
        
        // Группируем задачи по категориям
        tasksByCategory = Dictionary(grouping: tasksForSelectedDate, by: { $0.category })
    }
}

// Компонент для отображения задач из ToDoList
struct TasksFromToDoListView: View {
    @ObservedObject var listViewModel: ListViewModel
    let selectedDate: Date
    let categoryManager: CategoryManagementProtocol // Просто хранит ссылку
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Список задач")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.top, 10)
            
            // Получаем все задачи из списка на выбранную дату
            let items = getFilteredItemsForDate(selectedDate)
            
            if items.isEmpty {
                Text("Нет задач на этот день")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 15)
            } else {
                // Группируем задачи по категориям
                let groupedTasks = Dictionary(grouping: items) { item in 
                    item.categoryID ?? UUID() // Группируем по ID категории или создаем уникальный ID
                }
                
                ForEach(Array(groupedTasks.keys), id: \.self) { categoryID in
                    if let tasks = groupedTasks[categoryID] {
                        let categoryName = tasks.first?.categoryName ?? "Без категории"
                        let (categoryColor, categoryIcon) = getCategoryInfo(for: categoryID)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            // Заголовок категории
                            HStack {
                                Image(systemName: categoryIcon)
                                    .foregroundColor(categoryColor)
                                    .font(.system(size: 14))
                                
                                Text(categoryName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(tasks.count)")
                                    .font(.caption)
                                    .padding(6)
                                    .background(Circle().fill(categoryColor.opacity(0.3)))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 10)
                            
                            // Задачи в категории
                            ForEach(tasks) { task in
                                ToDoTaskRow(task: task, categoryColor: categoryColor)
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(categoryColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
    }
    
    // Фильтрация задач на выбранную дату
    private func getFilteredItemsForDate(_ date: Date) -> [ToDoItem] {
        return listViewModel.items.filter { item in
            Calendar.current.isDate(item.date, inSameDayAs: date)
        }
    }
    
    // Получение информации о категории (цвет и иконка)
    private func getCategoryInfo(for categoryID: UUID) -> (Color, String) {
        // Ищем категорию в списке категорий
        if let category = categoryManager.categories.first(where: { $0.id == categoryID }) {
            return (category.color, category.iconName)
        }
        
        // Если не нашли, используем стандартные значения
        let colors: [Color] = [.blue, .green, .orange, .red, .purple, .yellow]
        let hashValue = abs(categoryID.hashValue)
        let color = colors[hashValue % colors.count]
        
        // Используем различные иконки в зависимости от хеша
        let icons = ["tag.fill", "folder.fill", "list.bullet", "checkmark.circle.fill", 
                    "calendar", "book.fill", "note.text", "tray.fill"]
        let icon = icons[(hashValue / 2) % icons.count]
        
        return (color, icon)
    }
}

// Компонент для отображения строки задачи из ToDoList
struct ToDoTaskRow: View {
    let task: ToDoItem
    let categoryColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Индикатор выполнения
            Circle()
                .fill(task.isCompleted ? Color.green : Color.clear)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(task.isCompleted ? Color.green : categoryColor.opacity(0.7), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .strikethrough(task.isCompleted)
                
                if !task.content.isEmpty {
                    Text(task.content)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Индикатор приоритета
            if task.priority != .none {
                priorityIndicator(for: task.priority)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.darkGray).opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(getPriorityBorderColor(for: task.priority), lineWidth: task.priority != .none ? 1.5 : 0)
                )
        )
    }
    
    // Индикатор приоритета
    private func priorityIndicator(for priority: TaskPriority) -> some View {
        VStack(spacing: 1) {
            ForEach(0..<priority.rawValue, id: \.self) { _ in
                Rectangle()
                    .fill(getPriorityColor(for: priority))
                    .frame(width: 8, height: 2)
            }
        }
    }
    
    // Цвет приоритета
    private func getPriorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .high:
            return Color.red
        case .medium:
            return Color.orange
        case .low:
            return Color.green
        case .none:
            return Color.gray
        }
    }
    
    // Цвет рамки для приоритета
    private func getPriorityBorderColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .high:
            return Color.red.opacity(0.6)
        case .medium:
            return Color.orange.opacity(0.5)
        case .low:
            return Color.green.opacity(0.4)
        case .none:
            return Color.clear
        }
    }
}

// Форма для добавления новой задачи
struct NewTaskFormView: View {
    @ObservedObject var viewModel: ListViewModel
    @Binding var isPresented: Bool
    let selectedDate: Date
    
    @State private var taskTitle = ""
    @State private var taskContent = ""
    @State private var selectedCategory: TaskCategoryModel?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.098, green: 0.098, blue: 0.098).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Новая задача")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Дата: \(formattedDate(selectedDate))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        TextField("Название задачи", text: $taskTitle)
                            .padding()
                            .background(Color(.darkGray).opacity(0.6))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                        
                        TextField("Описание (опционально)", text: $taskContent)
                            .padding()
                            .background(Color(.darkGray).opacity(0.6))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                        
                        // Здесь можно добавить выбор категории
                        
                        Spacer()
                        
                        Button(action: {
                            // Добавляем новую задачу
                            addNewTask()
                            isPresented = false
                        }) {
                            Text("Добавить задачу")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                                .foregroundColor(.white)
                        }
                        .disabled(taskTitle.isEmpty)
                        .opacity(taskTitle.isEmpty ? 0.5 : 1)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    // Добавление новой задачи
    private func addNewTask() {
        if !taskTitle.isEmpty {
            if let category = selectedCategory {
                viewModel.presenter?.addItemWithCategory(
                    title: taskTitle,
                    content: taskContent,
                    category: category
                )
            } else {
                viewModel.presenter?.addItem(
                    title: taskTitle,
                    content: taskContent
                )
            }
        }
    }
    
    // Форматирование даты
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: date)
    }
}

// Компонент для отображения задач категории на циферблате
struct CategoryTasksView: View {
    let category: TaskCategoryModel
    let tasks: [TaskOnRing]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Заголовок категории
            HStack(spacing: 6) {
                Image(systemName: category.iconName)
                    .foregroundColor(category.color)
                    .font(.system(size: 16))
                
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(tasks.count)")
                    .font(.caption)
                    .padding(6)
                    .background(Circle().fill(category.color.opacity(0.3)))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            
            // Список задач категории
            VStack(spacing: 8) {
                ForEach(tasks) { task in
                    TaskRowCalendar(task: task)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(category.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// Компонент для отображения строки задачи в календаре
struct TaskRowCalendar: View {
    let task: TaskOnRing
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Время задачи
            Text(formatTime(task.startTime) + " - " + formatTime(task.endTime))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.darkGray).opacity(0.6))
        )
    }
    
    // Форматирование времени для отображения
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Расширение для создания скругления только по определенным углам
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
