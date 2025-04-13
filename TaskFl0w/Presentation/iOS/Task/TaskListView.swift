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

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $viewModel.searchText, isActive: $isSearchActive)
                
                List {
                    // Фильтруем задачи по выбранной категории
                    let filteredItems = viewModel.selectedCategory != nil 
                        ? viewModel.items.filter { item in
                            item.categoryID == viewModel.selectedCategory?.id
                        } 
                        : viewModel.items
                    
                    ForEach(filteredItems) { item in
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
                                }
                            )
                            .padding(.horizontal, 10)
                        }
                        // .listRowSeparator(.hidden)
                    }
                    .onDelete { indexSet in
                        let items = filteredItems
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
                
                // Показываем BottomBar только если поиск не активен
                if !isSearchActive {
                    BottomBar(
                        itemCount: filteredItems.count,
                        onAddTap: {
                            // Убедимся, что выбранная категория установлена перед открытием формы
                            if let selectedCategory = selectedCategory {
                                viewModel.selectedCategory = selectedCategory
                            }
                            showingAddForm = true
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .transition(.move(edge: .bottom))
                }
            }
           .fullScreenCover(isPresented: $showingAddForm) {
                ZStack {
                    FormTaskView(viewModel: viewModel, onDismiss: {
                        showingAddForm = false
                    })
                    .interactiveDismissDisabled(true)
                }
            }
            .fullScreenCover(item: $viewModel.editingItem) { item in
                FormTaskView(viewModel: viewModel, item: item, onDismiss: {
                    viewModel.editingItem = nil
                })
            }
        }
        // Сообщаем родительскому представлению о состоянии поиска
        .onChange(of: isSearchActive) { newValue in
            // Здесь можно выполнить дополнительные действия при изменении состояния поиска
            NotificationCenter.default.post(
                name: NSNotification.Name("SearchActiveStateChanged"),
                object: nil,
                userInfo: ["isActive": newValue]
            )
        }
    }
    
    // Вспомогательное свойство для фильтрации задач
    private var filteredItems: [ToDoItem] {
        if let selectedCategory = viewModel.selectedCategory {
            return viewModel.items.filter { item in
                item.categoryID == selectedCategory.id
            }
        } else {
            return viewModel.items
        }
    }
}
