//
//  TaskListView.swift
//  ToDoList
//
//  Created by Yan on 19/3/25.
//

import CoreData
import SwiftUI
import UIKit

struct TaskListView: View {
    @ObservedObject var viewModel: ListViewModel
    let selectedCategory: TaskCategoryModel?
    @State private var showingAddForm = false
    @State private var isSearchActive = false
    @State private var newTaskTitle = ""
    @State private var isAddingNewTask = false
    @State private var isKeyboardVisible = false
    @FocusState private var isNewTaskFocused: Bool
    @State private var showingPrioritySheet = false
    @State private var newTaskPriority: TaskPriority = .none
    @Binding var selectedDate: Date
    
    // Заменяем локальные состояния на ObservedObject
    @ObservedObject private var calendarState = CalendarState.shared
   
    
    private let topID = "top_of_list"

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 10)
                    
                    ScrollViewReader { scrollProxy in
                        List {
                            EmptyView()
                                .id(topID)
                                .frame(width: 0, height: 0)
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            
                            if viewModel.showCompletedTasksOnly {
                                Color.clear
                                .frame(height: 20)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }

                             // Заменяем локальные состояния на свойства CalendarState
                            if calendarState.isWeekCalendarVisible {
                                Color.clear
                                    .frame(height: 50)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }

                            if calendarState.isMonthCalendarVisible {
                                Color.clear
                                    .frame(height: 300)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                            
                            let items = viewModel.showCompletedTasksOnly 
                                ? viewModel.getAllArchivedItems()
                                : viewModel.getFilteredItems()
                            
                            if viewModel.showCompletedTasksOnly {
                                ArchivedTasksGroupView(
                                    items: items,
                                    categoryColor: viewModel.selectedCategory?.color ?? .blue,
                                    isSelectionMode: viewModel.isSelectionMode,
                                    selectedTasks: $viewModel.selectedTasks,
                                    onToggle: { taskId in
                                        viewModel.presenter?.toggleItem(id: taskId)
                                    },
                                    onEdit: { item in
                                        viewModel.editingItem = item
                                    },
                                    onDelete: { taskId in
                                        viewModel.presenter?.deleteItem(id: taskId)
                                    },
                                    onShare: { taskId in
                                        viewModel.presenter?.shareItem(id: taskId)
                                    }
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            } else {
                                ForEach(items) { item in
                                    TaskRow(
                                        item: item,
                                        onToggle: {
                                            viewModel.presenter?.toggleItem(id: item.id)
                                        },
                                        onEdit: {
                                            viewModel.editingItem = item
                                        },
                                        onDelete: {
                                            viewModel.presenter?.deleteItem(id: item.id)
                                        },
                                        onShare: {
                                            viewModel.presenter?.shareItem(id: item.id)
                                        },
                                        categoryColor: viewModel.selectedCategory?.color ?? .blue,
                                        isSelectionMode: viewModel.isSelectionMode,
                                        isInArchiveMode: viewModel.showCompletedTasksOnly,
                                        selectedTasks: $viewModel.selectedTasks
                                    )
                                    .padding(.trailing, 5)
                                    .listRowBackground(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color(red: 0.18, green: 0.18, blue: 0.18))
                                            
                                            if item.priority != .none {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(viewModel.getPriorityColor(for: item.priority), lineWidth: 1.5)
                                                    .opacity(item.isCompleted && !viewModel.isSelectionMode && !viewModel.showCompletedTasksOnly ? 0.5 : 1.0)
                                            }
                                        }
                                        .padding(.vertical, 5)
                                        .padding(.horizontal, 12)
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if viewModel.isSelectionMode {
                                            viewModel.toggleTaskSelection(taskId: item.id)
                                        } else {
                                            viewModel.presenter?.toggleItem(id: item.id)
                                        }
                                    }
                                    .listRowSeparator(.hidden)
                                }
                            }
                            
                            // Перемещаем добавление новой задачи сюда, в конец списка
                            if isAddingNewTask {
                                // Spacer()
                                //     .frame(height: 40)
                                //     .listRowSeparator(.hidden)
                                //     .listRowBackground(Color.clear)
                                //     .id("new_task_spacer")
                                
                                NewTaskInput(
                                    newTaskTitle: $newTaskTitle,
                                    isNewTaskFocused: _isNewTaskFocused,
                                    selectedPriority: $newTaskPriority,
                                    onSave: {
                                        viewModel.saveNewTask(title: newTaskTitle, priority: newTaskPriority)
                                        newTaskTitle = ""
                                        newTaskPriority = .none
                                        isAddingNewTask = false
                                        isNewTaskFocused = false
                                    }
                                )
                                .id("new_task_input")
                            }
                            
                            Color.clear
                                .frame(height: 90)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            
                        }
                        .listStyle(GroupedListStyle())
                        .onAppear {
                            if let selectedCategory = selectedCategory {
                                viewModel.selectedCategory = selectedCategory
                            }
                            viewModel.refreshData()
                        }
                        .onChange(of: isAddingNewTask) { oldValue, newValue in
                            if newValue == true {
                                withAnimation {
                                    // Меняем скролл к новому элементу внизу списка
                                    scrollProxy.scrollTo("new_task_input", anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                if viewModel.showCompletedTasksOnly {
                    VStack {
                        ArchiveView()
                        Spacer()
                    }
                }
                
                if !isSearchActive && !isKeyboardVisible {
                    if !isAddingNewTask {
                        VStack {
                            Spacer()
                            BottomBar(
                                onAddTap: {
                                    if let selectedCategory = selectedCategory {
                                        viewModel.selectedCategory = selectedCategory
                                    }
                                    isAddingNewTask = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        isNewTaskFocused = true
                                    }
                                },
                                isSelectionMode: $viewModel.isSelectionMode,
                                selectedTasks: $viewModel.selectedTasks,
                                onDeleteSelectedTasks: {
                                    viewModel.deleteSelectedTasks()
                                },
                                onChangePriorityForSelectedTasks: {
                                    showingPrioritySheet = true
                                },
                                onArchiveTapped: {
                                    viewModel.showCompletedTasksOnly.toggle()
                                },
                                onUnarchiveSelectedTasks: {
                                    viewModel.unarchiveSelectedTasks()
                                },
                                showCompletedTasksOnly: $viewModel.showCompletedTasksOnly
                            )
                            .transition(.move(edge: .bottom))
                            .padding(.bottom, 50)
                        }
                    }
                }

                if isAddingNewTask {
                    VStack {
                        Spacer().frame(height: UIScreen.main.bounds.height * 0.32)
                        // Изменяем расположение панели приоритетов
                        NewTaskPriorityBar(
                            selectedPriority: $newTaskPriority,
                            onSave: {
                                if !newTaskTitle.isEmpty {
                                    viewModel.saveNewTask(title: newTaskTitle, priority: newTaskPriority)
                                    newTaskTitle = ""
                                    newTaskPriority = .none
                                    isAddingNewTask = false
                                    isNewTaskFocused = false
                                }
                            },
                            onCancel: {
                                newTaskTitle = ""
                                newTaskPriority = .none
                                isAddingNewTask = false
                                isNewTaskFocused = false
                            }
                        )
                        .transition(.scale)
                        .padding(.bottom, 20) // Добавляем небольшой отступ снизу
                    }
                    .padding(.horizontal, 20)
                }
            }
            .scrollContentBackground(.hidden)
            .background{
                Color(red: 0.098, green: 0.098, blue: 0.098)
            }
            .actionSheet(isPresented: $showingPrioritySheet) {
                ActionSheet(
                    title: Text("Выберите приоритет"),
                    message: Text("Установить приоритет для выбранных задач"),
                    buttons: [
                        .default(Text("Высокий")) { 
                            viewModel.setPriorityForSelectedTasks(.high) 
                        },
                        .default(Text("Средний")) { 
                            viewModel.setPriorityForSelectedTasks(.medium) 
                        },
                        .default(Text("Низкий")) { 
                            viewModel.setPriorityForSelectedTasks(.low) 
                        },
                        .default(Text("Нет")) { 
                            viewModel.setPriorityForSelectedTasks(.none) 
                        },
                        .cancel(Text("Отмена"))
                    ]
                )
            }
        }
        
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
        
        .onChange(of: isSearchActive) { oldValue, newValue in
            NotificationCenter.default.post(
                name: NSNotification.Name("SearchActiveStateChanged"),
                object: nil,
                userInfo: ["isActive": newValue]
            )
        }
        .onChange(of: isAddingNewTask) { oldValue, newValue in
            NotificationCenter.default.post(
                name: NSNotification.Name("AddingTaskStateChanged"),
                object: nil,
                userInfo: ["isAddingTask": newValue]
            )
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            viewModel.selectedDate = newValue
            viewModel.refreshData()
        }
        .onChange(of: calendarState.isWeekCalendarVisible) { oldValue, newValue in
            print("isWeekCalendarVisible изменилось: \(oldValue) -> \(newValue)")
            withAnimation {
                // Можно добавить принудительное обновление
            }
        }
        .onChange(of: calendarState.isMonthCalendarVisible) { oldValue, newValue in
            withAnimation {
                // Дополнительная логика обновления при необходимости
            }
        }
    }
}


#Preview {
    TaskListView(viewModel: ListViewModel(), selectedCategory: nil, selectedDate: .constant(Date()))
}
