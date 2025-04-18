//
//  ContentView.swift
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
    @State private var isSelectionMode = false
    @State private var selectedTasks: Set<UUID> = []
    @State private var showingPrioritySheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $viewModel.searchText, isActive: $isSearchActive)
                
                // Добавляем индикатор режима архива
                if viewModel.showCompletedTasksOnly {
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 8) // Небольшой отступ сверху
                        
                        HStack {
                            Image(systemName: "archivebox.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                            
                            Text("Архив выполненных задач")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.darkGray).opacity(0.6))
                        )
                        .padding(.horizontal, 16)
                    }
                }
                
                List {
                    // Используем вычисляемое свойство для фильтрации
                    let items = getFilteredItems()
                    
                    // Показываем поле для новой задачи, если isAddingNewTask = true
                    if isAddingNewTask {
                        HStack {
                            TextField("Новая задача", text: $newTaskTitle)
                                .foregroundColor(.white)
                                .onSubmit {
                                    saveNewTask()
                                }
                                .focused($isNewTaskFocused)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.darkGray))
                                // .strokeBorder(viewModel.selectedCategory?.color ?? .blue, lineWidth: 1)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 8)
                        )
                        .listRowSeparator(.hidden)
                    }
                    
                    ForEach(items) { item in
                        VStack(spacing: 0) {
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
                                isSelectionMode: isSelectionMode,
                                isInArchiveMode: viewModel.showCompletedTasksOnly,
                                selectedTasks: $selectedTasks
                            )
                            .padding(.horizontal, 10)
                        }
                        .listRowBackground(
                            ZStack {
                                // Градиент фона в зависимости от приоритета
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.darkGray))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(getPriorityBorderColor(for: item.priority), lineWidth: item.priority != .none ? 1.5 : 0)
                                    )
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 8)
                            }
                        )
                        .listRowSeparator(.hidden)
                    }
                    .onDelete { indexSet in
                        let items = getFilteredItems()
                        indexSet.forEach { index in
                            let item = items[index]
                            viewModel.presenter?.deleteItem(id: item.id)
                        }
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
                        isSelectionMode: $isSelectionMode,
                        selectedTasks: $selectedTasks,
                        onDeleteSelectedTasks: {
                            // Удаляем все выбранные задачи
                            for taskId in selectedTasks {
                                viewModel.presenter?.deleteItem(id: taskId)
                            }
                            // Очищаем множество выбранных задач
                            selectedTasks.removeAll()
                        },
                        onChangePriorityForSelectedTasks: {
                            // Отображаем меню выбора приоритета и применяем выбранный приоритет
                            showPriorityActionSheet()
                        },
                        onArchiveTapped: {
                            // Переключаем режим отображения выполненных задач
                            viewModel.showCompletedTasksOnly.toggle()
                        },
                        onUnarchiveSelectedTasks: {
                            // Возвращаем выбранные задачи из архива
                            for taskId in selectedTasks {
                                viewModel.presenter?.toggleItem(id: taskId) // Меняем статус isCompleted на false
                            }
                            // Очищаем множество выбранных задач
                            selectedTasks.removeAll()
                        },
                        showCompletedTasksOnly: $viewModel.showCompletedTasksOnly
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
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
                            setPriorityForSelectedTasks(.high) 
                        },
                        .default(Text("Средний")) { 
                            setPriorityForSelectedTasks(.medium) 
                        },
                        .default(Text("Низкий")) { 
                            setPriorityForSelectedTasks(.low) 
                        },
                        .default(Text("Нет")) { 
                            setPriorityForSelectedTasks(.none) 
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
    
    // Функция для сохранения новой задачи
    private func saveNewTask() {
        if !newTaskTitle.isEmpty {
            if let category = viewModel.selectedCategory {
                viewModel.presenter?.addItemWithCategory(
                    title: newTaskTitle,
                    content: "",
                    category: category
                )
            } else {
                viewModel.presenter?.addItem(
                    title: newTaskTitle,
                    content: ""
                )
            }
            newTaskTitle = ""
        }
        // Закрываем форму ввода независимо от того, пуст ли ввод
        isAddingNewTask = false
        isNewTaskFocused = false
    }
    
    // Обновляем функцию фильтрации задач для отображения выполненных задач
    private func getFilteredItems() -> [ToDoItem] {
        var filteredItems: [ToDoItem]
        
        // Сначала фильтруем по категории, если она выбрана
        if let selectedCategory = viewModel.selectedCategory {
            filteredItems = viewModel.items.filter { item in
                item.categoryID == selectedCategory.id
            }
        } else {
            filteredItems = viewModel.items
        }
        
        // Если включен режим просмотра выполненных задач, отфильтровываем только их
        if viewModel.showCompletedTasksOnly {
            filteredItems = filteredItems.filter { item in
                item.isCompleted
            }
        }
        
        // Сортируем задачи
        return filteredItems.sorted { (item1, item2) -> Bool in
            // Если мы в режиме выполненных задач
            if viewModel.showCompletedTasksOnly {
                // Сначала сортируем по приоритету
                if item1.priority != item2.priority {
                    return item1.priority.rawValue > item2.priority.rawValue
                }
                
                // Если приоритеты одинаковые, сортируем по дате завершения
                // (от новых к старым)
                return item1.date > item2.date
            } else {
                // Стандартная сортировка
                // Если статус завершения разный, незавершенные идут вначале
                if item1.isCompleted != item2.isCompleted {
                    return !item1.isCompleted
                }
                
                // Если статус завершения одинаковый, сортируем по приоритету
                return item1.priority.rawValue > item2.priority.rawValue
            }
        }
    }
    
    private func showPriorityActionSheet() {
        showingPrioritySheet = true
    }
    
    private func setPriorityForSelectedTasks(_ priority: TaskPriority) {
        for taskId in selectedTasks {
            viewModel.presenter?.changePriority(id: taskId, priority: priority)
        }
        // Выходим из режима выбора после установки приоритета
        isSelectionMode = false
    }
    
    // Вспомогательный метод для получения цвета рамки в зависимости от приоритета
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

#Preview {
    TaskListView(viewModel: ListViewModel(), selectedCategory: nil)
}
