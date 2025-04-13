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

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $viewModel.searchText)
                
                // Отображение выбранной категории
                if let category = viewModel.selectedCategory {
                    HStack {
                        Circle()
                            .fill(category.color)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Image(systemName: category.iconName)
                                    .foregroundColor(.white)
                                    .font(.system(size: 10))
                            )
                        
                        Text("Категория: \(category.rawValue)")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Button(action: {
                            // Сбрасываем выбранную категорию
                            withAnimation {
                                viewModel.selectedCategory = nil
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                }
                
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
