//
//  TaskListView.swift
//  ToDoList
//
//  Created by Yan on 19/3/25.
//

import CoreData
import SwiftUI

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

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $viewModel.searchText, isActive: $isSearchActive)
                
                // Добавляем индикатор режима архива
                if viewModel.showCompletedTasksOnly {
                    ArchiveView()
                }
                
                List {
                    // Показываем поле для новой задачи, если isAddingNewTask = true
                    if isAddingNewTask {
                        NewTaskInput(
                            newTaskTitle: $newTaskTitle,
                            isNewTaskFocused: _isNewTaskFocused,
                            onSave: {
                                viewModel.saveNewTask(title: newTaskTitle)
                                newTaskTitle = ""
                                isAddingNewTask = false
                                isNewTaskFocused = false
                            }
                        )
                    }
                    
                    // Используем метод из ViewModel для фильтрации
                    let items = viewModel.getFilteredItems()
                    
                    // Отображаем все задачи в одном списке без группировки по приоритету
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
                        .padding(.horizontal, 10)
                        .listRowBackground(
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.darkGray))
                                
                                // Добавляем внешний бордер для задач с приоритетом
                                if item.priority != .none {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(viewModel.getPriorityColor(for: item.priority), lineWidth: 1.5)
                                        .opacity(item.isCompleted && !viewModel.isSelectionMode && !viewModel.showCompletedTasksOnly ? 0.5 : 1.0)
                                }
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 8)
                        )
                        .contentShape(Rectangle())  // Добавляем форму для регистрации нажатий
                        .onTapGesture {
                            if viewModel.isSelectionMode {
                                // В режиме выбора используем метод ViewModel
                                viewModel.toggleTaskSelection(taskId: item.id)
                            } else {
                                // В обычном режиме, нажатие делает задачу завершенной
                                viewModel.presenter?.toggleItem(id: item.id)
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(GroupedListStyle())
                .onAppear {
                    // При появлении обновляем выбранную категорию из пропса и обновляем данные
                    if let selectedCategory = selectedCategory {
                        viewModel.selectedCategory = selectedCategory
                    }
                    viewModel.refreshData()
                }
                
                // Показываем BottomBar только если поиск не активен, не создается новая задача и клавиатура не видна
                if !isSearchActive && !isAddingNewTask && !isKeyboardVisible {
                    BottomBar(
                        onAddTap: {
                            // Убедимся, что выбранная категория установлена перед открытием формы
                            if let selectedCategory = selectedCategory {
                                viewModel.selectedCategory = selectedCategory
                            }
                            // Вместо открытия формы, показываем строку для новой задачи
                            isAddingNewTask = true
                            // Устанавливаем фокус с небольшой задержкой
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
                            // Отображаем меню выбора приоритета
                            showingPrioritySheet = true
                        },
                        onArchiveTapped: {
                            // Переключаем режим отображения выполненных задач
                            viewModel.showCompletedTasksOnly.toggle()
                        },
                        onUnarchiveSelectedTasks: {
                            viewModel.unarchiveSelectedTasks()
                        },
                        showCompletedTasksOnly: $viewModel.showCompletedTasksOnly
                    )
                    .transition(.move(edge: .bottom))
                }
            }
            .scrollContentBackground(.hidden)
            .background{
                Color(red: 0.098, green: 0.098, blue: 0.098)
            }
            .fullScreenCover(item: $viewModel.editingItem) { item in
                FormTaskView(viewModel: viewModel, item: item, onDismiss: {
                    viewModel.editingItem = nil
                })
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
        
        // Отслеживаем появление клавиатуры
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        // Отслеживаем скрытие клавиатуры
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
        
        // Обновленный синтаксис onChange для iOS 17
        .onChange(of: isSearchActive) { oldValue, newValue in
            // Здесь можно выполнить дополнительные действия при изменении состояния поиска
            NotificationCenter.default.post(
                name: NSNotification.Name("SearchActiveStateChanged"),
                object: nil,
                userInfo: ["isActive": newValue]
            )
        }
        // Добавляем обработчик изменения состояния создания новой задачи
        .onChange(of: isAddingNewTask) { oldValue, newValue in
            // Если режим создания новой задачи активирован,
            // то отправляем уведомление для скрытия докбара
            NotificationCenter.default.post(
                name: NSNotification.Name("AddingTaskStateChanged"),
                object: nil,
                userInfo: ["isAddingTask": newValue]
            )
        }
    }
}

#Preview {
    TaskListView(viewModel: ListViewModel(), selectedCategory: nil)
}
