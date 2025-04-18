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
                                selectedTasks: $selectedTasks
                            )
                            .padding(.horizontal, 10)
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.darkGray))
                                // .strokeBorder(item.categoryID == viewModel.selectedCategory?.id ? viewModel.selectedCategory?.color ?? .blue : .blue, lineWidth: 2)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 8)
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
                        }
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
    
    // Вспомогательная функция для фильтрации задач
    private func getFilteredItems() -> [ToDoItem] {
        var filteredItems: [ToDoItem]
        
        if let selectedCategory = viewModel.selectedCategory {
            filteredItems = viewModel.items.filter { item in
                item.categoryID == selectedCategory.id
            }
        } else {
            filteredItems = viewModel.items
        }
        
        // Сортируем задачи по приоритету (от высокого к низкому)
        // Сначала по приоритету (в обратном порядке - высокий приоритет в начале), 
        // затем по статусу завершения (незавершенные в начале)
        return filteredItems.sorted { (item1, item2) -> Bool in
            // Если статус завершения разный, незавершенные идут вначале
            if item1.isCompleted != item2.isCompleted {
                return !item1.isCompleted
            }
            
            // Если статус завершения одинаковый, сортируем по приоритету
            // Высокий приоритет (3) должен быть вначале списка
            return item1.priority.rawValue > item2.priority.rawValue
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
}

#Preview {
    TaskListView(viewModel: ListViewModel(), selectedCategory: nil)
}
