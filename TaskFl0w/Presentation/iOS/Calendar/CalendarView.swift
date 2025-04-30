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
                        TasksFromToDoListView(
                            listViewModel: listViewModel, 
                            selectedDate: temporaryDate,
                            categoryManager: viewModel.categoryManagement,
                            clockTasks: filteredClockTasks
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
        // Фильтруем все задачи из SharedState, а не только viewModel.tasks
        filteredClockTasks = viewModel.sharedState.tasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: temporaryDate)
        }
    }
}
