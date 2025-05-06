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
    
    // Добавляем ID для прокрутки к началу списка
    private let topID = "top_of_list"

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Основное содержимое списка
                VStack(spacing: 0) {
                    // Добавляем отступ сверху, чтобы всё содержимое было ниже на 10
                    Spacer()
                        .frame(height: 10)
                    
                    // Добавляем ScrollViewReader для управления прокруткой
                    ScrollViewReader { scrollProxy in
                        List {
                            // Вставляем специальный элемент с ID в начало списка
                            EmptyView()
                                .id(topID)
                                .frame(width: 0, height: 0)
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            
                            // Добавляем отступ сверху 60 когда отображается архив
                            if viewModel.showCompletedTasksOnly {
                                Color.clear
                                .frame(height: 40)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            
                            // Показываем поле для новой задачи, если isAddingNewTask = true
                            if isAddingNewTask {
                                Spacer()
                                    .frame(height: 40)
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                
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
                            }
                            
                            // Используем разные методы в зависимости от режима
                            let items = viewModel.showCompletedTasksOnly 
                                ? viewModel.getAllArchivedItems() // Для архива берем все архивные задачи
                                : viewModel.getFilteredItems() // Для обычного режима - только задачи на выбранную дату
                            
                            // Отображаем задачи в зависимости от режима
                            if viewModel.showCompletedTasksOnly {
                                // Используем новый компонент для отображения задач, сгруппированных по датам
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
                            } else {
                                // Стандартное отображение задач (без группировки)
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
                                            
                                            // Добавляем внешний бордер для задач с приоритетом
                                            if item.priority != .none {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(viewModel.getPriorityColor(for: item.priority), lineWidth: 1.5)
                                                    .opacity(item.isCompleted && !viewModel.isSelectionMode && !viewModel.showCompletedTasksOnly ? 0.5 : 1.0)
                                            }
                                        }
                                        .padding(.vertical, 5)
                                        .padding(.horizontal, 12)
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
                            
                            // Добавляем пустой элемент для отступа снизу
                            Color.clear
                                .frame(height: 90)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .listStyle(GroupedListStyle())
                        .onAppear {
                            // При появлении обновляем выбранную категорию из пропса и обновляем данные
                            if let selectedCategory = selectedCategory {
                                viewModel.selectedCategory = selectedCategory
                            }
                            viewModel.refreshData()
                        }
                        // Отслеживаем изменение isAddingNewTask для прокрутки к началу списка
                        .onChange(of: isAddingNewTask) { oldValue, newValue in
                            if newValue == true {
                                // Прокручиваем к началу списка с анимацией
                                withAnimation {
                                    scrollProxy.scrollTo(topID, anchor: .top)
                                }
                            }
                        }
                    }
                }
                
                // Добавляем индикатор режима архива на уровне ZStack перед SearchBar
                if viewModel.showCompletedTasksOnly {
                    VStack {
                        ArchiveView()
                        Spacer()
                    }
                }
                
                // SearchBar сверху с эффектом размытия для фона
                // VStack {
                //     SearchBar(text: $viewModel.searchText, isActive: $isSearchActive)
                // }

                // Перемещаем BottomBar на уровень ZStack для изменения порядка слоев
                if !isSearchActive && !isKeyboardVisible {
                    // Для стандартной панели используем существующую реализацию
                    if !isAddingNewTask {
                        VStack {
                            Spacer()
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
                            .padding(.bottom, 50)
                        }
                    }
                }

                // Панель выбора приоритета при создании новой задачи
                // Размещаем её в отдельном ZStack слое для лучшего позиционирования
                if isAddingNewTask {
                    VStack {
                        // Размещаем панель примерно на середине экрана
                        Spacer().frame(height: UIScreen.main.bounds.height * 0.28)
                        
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
                        
                        Spacer()
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
        // В body добавляем обработчик изменений даты
        .onChange(of: selectedDate) { oldValue, newValue in
            // Обновляем дату в viewModel
            viewModel.selectedDate = newValue
            // И принудительно обновляем данные
            viewModel.refreshData()
        }
    }
}


#Preview {
    TaskListView(viewModel: ListViewModel(), selectedCategory: nil, selectedDate: .constant(Date()))
}
