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
                                categoryColor: viewModel.selectedCategory?.color ?? .blue
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
                        itemCount: getFilteredItems().count,
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
        if let selectedCategory = viewModel.selectedCategory {
            return viewModel.items.filter { item in
                item.categoryID == selectedCategory.id
            }
        } else {
            return viewModel.items
        }
    }
}

#Preview {
    TaskListView(viewModel: ListViewModel(), selectedCategory: nil)
}
