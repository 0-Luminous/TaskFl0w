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
//    @State private var selectedMode: BottomBarCalendar.ViewMode = .week
    @State private var showAddTaskForm = false
    @State private var filteredClockTasks: [TaskOnRing] = [] // Задачи циферблата на выбранную дату
    
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
                        // TasksFromToDoListView(
                        //     listViewModel: listViewModel, 
                        //     selectedDate: temporaryDate,
                        //     categoryManager: viewModel.categoryManagement,
                        //     clockTasks: filteredClockTasks
                        // )
                        // .padding(.horizontal)
                        TaskTimeline(
                            tasks: filteredClockTasks,
                            selectedDate: temporaryDate,
                            listViewModel: listViewModel,
                            categoryManager: viewModel.categoryManagement
                        )
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 100) // Увеличиваем отступ для BottomBar
                }
                .background(Color(red: 0.098, green: 0.098, blue: 0.098))
                .edgesIgnoringSafeArea(.top)
                
//                VStack {
//                    Spacer()
//                    BottomBarCalendar(selectedMode: $selectedMode) {
//                        // Действие при нажатии на кнопку добавления
//                        showAddTaskForm = true
//                    }
//                    .padding(.horizontal)
//                    .padding(.bottom, 16)
//                }
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
                        
                        // Получаем все задачи из SharedState
                        let allTasks = viewModel.sharedState.tasks
                        
                        // Фильтруем задачи на выбранную дату
                        let tasksOnSelectedDate = allTasks.filter { task in
                            Calendar.current.isDate(task.startTime, inSameDayAs: temporaryDate)
                        }
                        
                        // Получаем незавершенные задачи с предыдущих дней
                        let incompleteTasksFromPreviousDays = allTasks.filter { task in
                            // Проверяем, что задача не выполнена и относится к дате до выбранной
                            !task.isCompleted && 
                            Calendar.current.compare(task.startTime, to: temporaryDate, toGranularity: .day) == .orderedAscending
                        }
                        
                        // Объединяем задачи текущего дня и невыполненные с предыдущих дней
                        viewModel.tasks = tasksOnSelectedDate + incompleteTasksFromPreviousDays
                        
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
        .onChange(of: temporaryDate) { oldValue, newValue in
            // Обновляем список задач при изменении даты
            listViewModel.refreshData()
            
            // Сразу обновляем задачи циферблата для выбранной даты
            updateFilteredClockTasks()
        }
        .onAppear {
            listViewModel.refreshData() // Загружаем задачи из ToDo
            updateFilteredClockTasks() // Начальное обновление задач циферблата
        }
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
