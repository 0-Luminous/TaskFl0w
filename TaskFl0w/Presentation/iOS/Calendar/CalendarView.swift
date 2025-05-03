//
//  CalendarView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

// Определяем режимы отображения календаря
enum CalendarViewMode {
    case weekSheet // Компактный режим шторки с неделей
    case fullCalendar // Полноэкранный календарь (месяц)
}

struct CalendarView: View {
    @StateObject private var viewModel: ClockViewModel
    @StateObject private var listViewModel = ListViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var temporaryDate: Date // Временная дата для хранения выбора
    @State private var viewMode: CalendarViewMode = .weekSheet // По умолчанию компактный режим с неделей
    @State private var showAddTaskForm = false
    @State private var filteredClockTasks: [TaskOnRing] = [] // Задачи циферблата на выбранную дату
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    // Константы для управления жестами
    private let dragThreshold: CGFloat = 100 // Уменьшен для большей отзывчивости
    private let minDragOffset: CGFloat = -50 // Разрешаем небольшое смещение вверх
    private let maxDragOffset: CGFloat = 350 // Увеличен для большего визуального отклика
    
    init(viewModel: ClockViewModel, initialMode: CalendarViewMode = .weekSheet) {
        _viewModel = StateObject(wrappedValue: viewModel)
        // Инициализируем временную дату текущей выбранной датой
        _temporaryDate = State(initialValue: viewModel.selectedDate)
        _viewMode = State(initialValue: initialMode)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Фоновый цвет
                Color(red: 0.098, green: 0.098, blue: 0.098)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Заголовок и основной контейнер календаря
                    ZStack {
                        // Цветной фон 
                        RoundedRectangle(cornerRadius: 30)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                            .edgesIgnoringSafeArea(.top)
                            .frame(height: viewMode == .fullCalendar ? 550 : 300)
                            .offset(y: -40)
                        
                        // Содержимое календаря
                        VStack(spacing: 5) {
                            if viewMode == .weekSheet {
                                // Компактный вид с неделей
                                WeekCalendarView(selectedDate: $temporaryDate)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.black.opacity(0.5))
                                            .shadow(color: .black.opacity(0.2), radius: 5)
                                    )
                                    .padding(.horizontal)
                                
                                // Улучшенный индикатор свайпа
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.down")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("Месяц")
                                        .font(.caption)
                                    Image(systemName: "arrow.down")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.15))
                                )
                                .padding(.top, 10)
                                
                            } else {
                                // Полный календарь с месяцем
                                VStack(spacing: 0) {
                                    DatePicker("", selection: $temporaryDate, displayedComponents: .date)
                                        .datePickerStyle(.graphical)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.black.opacity(0.5))
                                                .shadow(color: .black.opacity(0.2), radius: 5)
                                        )
                                        .padding(.horizontal)
                                        .colorScheme(.dark) // Принудительно тёмная схема для календаря
                                        .padding(.top, 0)
                                    
                                    // Улучшенный индикатор свайпа вверх
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.up")
                                            .font(.system(size: 10, weight: .bold))
                                        Text("Неделя")
                                            .font(.caption)
                                        Image(systemName: "arrow.up")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.15))
                                    )
                                    .padding(.top, 10)
                                }
                                .offset(y: 0)
                            }
                            
                            Spacer().frame(height: 20)
                        }
                        .offset(y: viewMode == .weekSheet ? 50 : 20)
                        .offset(y: isDragging ? dragOffset : 0)
                        
                        // Индикатор состояния над календарем
                        if isDragging {
                            Text(dragOffset > dragThreshold/2 && viewMode == .weekSheet ? 
                                 "Открыть месяц" : 
                                 dragOffset < -dragThreshold/2 && viewMode == .fullCalendar ? 
                                 "Вернуться к неделе" : "")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(10)
                                .opacity(min(1.0, abs(dragOffset) / dragThreshold))
                                .offset(y: -50)
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                isDragging = true
                                // Ограничиваем диапазон drag offset 
                                dragOffset = min(maxDragOffset, max(minDragOffset, gesture.translation.height))
                            }
                            .onEnded { gesture in
                                // Плавное завершение жеста с анимацией
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isDragging = false
                                    dragOffset = 0
                                    
                                    // Меняем режим если прошли порог
                                    if gesture.translation.height > dragThreshold && viewMode == .weekSheet {
                                        viewMode = .fullCalendar
                                    } else if gesture.translation.height < -dragThreshold && viewMode == .fullCalendar {
                                        viewMode = .weekSheet
                                    }
                                }
                            }
                    )
                    
                    Spacer()
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
                        viewModel.objectWillChange.send()
                        
                        // Обновляем задачи на выбранную дату
                        updateTasksForSelectedDate()
                        
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
        .onChange(of: temporaryDate) { _, _ in
            listViewModel.refreshData()
            updateFilteredClockTasks()
        }
        .onAppear {
            listViewModel.refreshData()
            updateFilteredClockTasks()
        }
    }
    
    // Обновляет задачи в viewModel для выбранной даты
    private func updateTasksForSelectedDate() {
        // Получаем все задачи из SharedState
        let allTasks = viewModel.sharedState.tasks
        
        // Фильтруем задачи на выбранную дату
        let tasksOnSelectedDate = allTasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: temporaryDate)
        }
        
        // Получаем незавершенные задачи с предыдущих дней
        let incompleteTasksFromPreviousDays = allTasks.filter { task in
            !task.isCompleted && 
            Calendar.current.compare(task.startTime, to: temporaryDate, toGranularity: .day) == .orderedAscending
        }
        
        // Объединяем задачи текущего дня и невыполненные с предыдущих дней
        viewModel.tasks = tasksOnSelectedDate + incompleteTasksFromPreviousDays
        
        // Обновляем также состояние clockState
        viewModel.clockState.selectedDate = temporaryDate
        viewModel.updateMarkersViewModel()
    }
    
    // Функция для обновления отфильтрованных задач циферблата
    private func updateFilteredClockTasks() {
        // Получаем все задачи из SharedState
        let allTasks = viewModel.sharedState.tasks
        
        // Фильтруем задачи на выбранную дату
        let tasksOnSelectedDate = allTasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: temporaryDate)
        }
        
        // Получаем незавершенные задачи с предыдущих дней
        let incompleteTasksFromPreviousDays = allTasks.filter { task in
            // Проверяем, что:
            // 1. Задача не выполнена
            // 2. Задача относится к дате ДО выбранной даты
            !task.isCompleted && 
            Calendar.current.compare(task.startTime, to: temporaryDate, toGranularity: .day) == .orderedAscending
        }
        
        // Объединяем задачи текущего дня и невыполненные с предыдущих дней
        filteredClockTasks = tasksOnSelectedDate + incompleteTasksFromPreviousDays
    }
}
