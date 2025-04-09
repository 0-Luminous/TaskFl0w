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
}
