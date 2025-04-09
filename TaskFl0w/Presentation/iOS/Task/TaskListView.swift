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

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal, 17)
                    .padding(.bottom, 16)

                List {
                    ForEach(viewModel.items) { item in
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
                        .listRowSeparator(.hidden)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            let item = viewModel.items[index]
                            viewModel.presenter?.deleteItem(id: item.id)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .onAppear {
                    viewModel.onViewDidLoad()
                }
                
                BottomBar(
                    itemCount: viewModel.items.count,
                    onAddTap: {
                        viewModel.isAddingNewItem = true
                    }
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .fullScreenCover(isPresented: $viewModel.isAddingNewItem) {
                AddOrEditTaskView(viewModel: viewModel)
            }
            .fullScreenCover(item: $viewModel.editingItem) { item in
                AddOrEditTaskView(viewModel: viewModel, item: item)
            }
        }
    }
}
