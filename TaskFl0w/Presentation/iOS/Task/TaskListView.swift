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
                    // Показываем поле для новой задачи, если isAddingNewTask = true
                    if isAddingNewTask {
                        HStack {
                            TextField("Новая задача", text: $newTaskTitle, axis: .vertical)
                                .foregroundColor(.white)
                                .lineLimit(3) // Разрешить до 3 строк
                                .onSubmit {
                                    saveNewTask()
                                }
                                .submitLabel(.done)
                                .focused($isNewTaskFocused)
                                .keyboardType(.default)
                                .autocapitalization(.sentences)
                                .disableAutocorrection(false)
                                // Специальный модификатор для обработки ввода
                                .onChange(of: newTaskTitle) { oldValue, newValue in
                                    // Если в тексте есть символ новой строки, значит была нажата кнопка Return
                                    if newValue.contains("\n") {
                                        // Удаляем символ новой строки
                                        newTaskTitle = newValue.replacingOccurrences(of: "\n", with: "")
                                        // Сохраняем задачу
                                        saveNewTask()
                                    }
                                }
                        }
                        .padding(.horizontal, 10)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.darkGray))
                                .padding(.vertical, 5)
                                .padding(.horizontal, 8)
                        )
                        .listRowSeparator(.hidden)
                    }
                    
                    // Используем вычисляемое свойство для фильтрации
                    let items = getFilteredItems()
                    
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
                            isSelectionMode: isSelectionMode,
                            isInArchiveMode: viewModel.showCompletedTasksOnly,
                            selectedTasks: $selectedTasks
                        )
                        .padding(.horizontal, 10)
                        .listRowBackground(
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.darkGray))
                                
                                // Добавляем внешний бордер для задач с приоритетом
                                if item.priority != .none {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(getPriorityColor(for: item.priority), lineWidth: 1.5)
                                        .opacity(item.isCompleted && !isSelectionMode && !viewModel.showCompletedTasksOnly ? 0.5 : 1.0)
                                }
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 8)
                        )
                        .contentShape(Rectangle())  // Добавляем форму для регистрации нажатий
                        .onTapGesture {
                            if isSelectionMode {
                                // В режиме выбора, нажатие выбирает/снимает выбор задачи
                                if selectedTasks.contains(item.id) {
                                    selectedTasks.remove(item.id)
                                } else {
                                    selectedTasks.insert(item.id)
                                }
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
                    category: category
                )
            } else {
                viewModel.presenter?.addItem(
                    title: newTaskTitle
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
    
    // Вспомогательные методы для приоритетов
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

    private func priorityIcon(for priority: TaskPriority) -> some View {
        let systemName: String
        
        switch priority {
        case .high:
            systemName = "exclamationmark.triangle.fill"
        case .medium:
            systemName = "exclamationmark.circle.fill"
        case .low:
            systemName = "arrow.up.circle.fill"
        case .none:
            systemName = "list.bullet"
        }
        
        return Image(systemName: systemName)
    }

    private func getPriorityText(for priority: TaskPriority) -> String {
        switch priority {
        case .high:
            return "Высокий приоритет"
        case .medium:
            return "Средний приоритет"
        case .low:
            return "Низкий приоритет"
        case .none:
            return "Без приоритета"
        }
    }
}

#Preview {
    TaskListView(viewModel: ListViewModel(), selectedCategory: nil)
}
