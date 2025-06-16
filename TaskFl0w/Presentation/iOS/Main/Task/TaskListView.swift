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
    @State private var showPrioritySelection = false
    // Добавляем состояние для календаря переноса задач
    @State private var showingDatePicker = false
    @State private var selectedTargetDate = Date()
    // Добавляем состояние для deadline picker
    @State private var showingDeadlinePicker = false
    @State private var selectedDeadlineDate = Date()
    // Добавляем состояние для предупреждения об удалении
    @State private var showingDeleteAlert = false
    @Binding var selectedDate: Date

    // Заменяем локальные состояния на ObservedObject
    @ObservedObject private var calendarState = CalendarState.shared
    @ObservedObject private var themeManager = ThemeManager.shared

    private let topID = "top_of_list"

    // Функция для генерации виброотдачи
    private func generateHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {

        ZStack(alignment: .top) {
            backgroundView

            VStack(spacing: 0) {
                mainScrollView
            }

            overlayViews
            bottomBarContainer
        }
        .scrollContentBackground(.hidden)
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
        ) { _ in
            isKeyboardVisible = true
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
        ) { _ in
            isKeyboardVisible = false
        }
        .onChange(of: isSearchActive) { oldValue, newValue in
            NotificationCenter.default.post(
                name: NSNotification.Name("SearchActiveStateChanged"),
                object: nil,
                userInfo: ["isActive": newValue]
            )
        }
        .onChange(of: isAddingNewTask) { oldValue, newValue in
            NotificationCenter.default.post(
                name: NSNotification.Name("AddingTaskStateChanged"),
                object: nil,
                userInfo: ["isAddingTask": newValue]
            )
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            viewModel.selectedDate = newValue
            viewModel.refreshData()
        }
        .onChange(of: calendarState.isWeekCalendarVisible) { oldValue, newValue in
            print("isWeekCalendarVisible изменилось: \(oldValue) -> \(newValue)")
        }
        .onChange(of: calendarState.isMonthCalendarVisible) { oldValue, newValue in
            // Дополнительная логика обновления при необходимости
        }
        .actionSheet(isPresented: $showingPrioritySheet) {
            priorityActionSheet
        }
        .sheet(isPresented: $showingDatePicker) {
            transferTaskSheet
        }
        .sheet(isPresented: $showingDeadlinePicker) {
            deadlineTaskSheet
        }
        .alert("Удаление задач", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive) {
                viewModel.deleteSelectedTasks()
            }
        } message: {
            Text(
                "Вы уверены, что хотите удалить выбранные задачи (\(viewModel.selectedTasks.count))?"
            )
        }
    }

    // MARK: - Computed Properties для разбивки сложного body

    private var backgroundView: some View {
        (themeManager.isDarkMode
            ? Color(red: 0.098, green: 0.098, blue: 0.098)
            : Color(red: 0.95, green: 0.95, blue: 0.95))
            .ignoresSafeArea()
    }

    private var mainScrollView: some View {
        ScrollViewReader { scrollProxy in
            List {
                listHeader
                calendarSpacers
                taskContent
                newTaskSection
                bottomSpacer
            }
            .listStyle(GroupedListStyle())
            .onAppear {
                setupInitialState()
            }
            .onChange(of: isAddingNewTask) { oldValue, newValue in
                if newValue == true {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        scrollProxy.scrollTo("new_task_input", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var listHeader: some View {
        Group {
            EmptyView()
                .id(topID)
                .frame(width: 0, height: 0)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            if viewModel.showCompletedTasksOnly {
                Color.clear
                    .frame(height: 20)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
    }

    private var calendarSpacers: some View {
        Group {
            if calendarState.isWeekCalendarVisible {
                Color.clear
                    .frame(height: 70)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if calendarState.isMonthCalendarVisible {
                Color.clear
                    .frame(height: 300)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
    }

    private var taskContent: some View {
        let items =
            viewModel.showCompletedTasksOnly
            ? viewModel.getAllArchivedItems()
            : viewModel.getFilteredItems()

        return Group {
            if viewModel.showCompletedTasksOnly {
                archivedTasksView(items: items)
            } else {
                regularTasksView(items: items)
            }
        }
    }

    private func archivedTasksView(items: [ToDoItem]) -> some View {
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
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func regularTasksView(items: [ToDoItem]) -> some View {
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
            .listRowBackground(taskRowBackground(for: item))
            .contentShape(Rectangle())
            .onTapGesture {
                generateHapticFeedback()
                if viewModel.isSelectionMode {
                    viewModel.toggleTaskSelection(taskId: item.id)
                } else {
                    viewModel.presenter?.toggleItem(id: item.id)
                }
            }
            .listRowSeparator(.hidden)
        }
    }

    private func taskRowBackground(for item: ToDoItem) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundFillColor)
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)

            if item.priority != .none {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(viewModel.getPriorityColor(for: item.priority), lineWidth: 1.5)
                    .opacity(priorityOpacity(for: item))
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 12)
    }

    private var backgroundFillColor: Color {
        themeManager.isDarkMode
            ? Color(red: 0.18, green: 0.18, blue: 0.18)
            : Color(red: 0.9, green: 0.9, blue: 0.9)
    }

    private func priorityOpacity(for item: ToDoItem) -> Double {
        item.isCompleted && !viewModel.isSelectionMode && !viewModel.showCompletedTasksOnly
            ? 0.5 : 1.0
    }

    private var newTaskSection: some View {
        Group {
            if isAddingNewTask {
                TaskInput(
                    newTaskTitle: $newTaskTitle,
                    isNewTaskFocused: _isNewTaskFocused,
                    selectedPriority: $newTaskPriority,
                    onSave: {
                        viewModel.saveNewTask(title: newTaskTitle, priority: newTaskPriority)
                        resetNewTask()
                    }
                )
                .id("new_task_input")
            }
        }
    }

    private var bottomSpacer: some View {
        Color.clear
            .frame(height: 160)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }

    private var overlayViews: some View {
        Group {
            if viewModel.showCompletedTasksOnly {
                VStack {
                    ArchiveView()
                    Spacer()
                }
            }

            if isAddingNewTask {
                newTaskOverlay
            }
        }
    }

    private var newTaskOverlay: some View {
        VStack {
            Spacer().frame(height: UIScreen.main.bounds.height * 0.32)

            PrioritySelectionView(
                selectedPriority: $newTaskPriority,
                onSave: {
                    showPrioritySelection = false
                    if !newTaskTitle.isEmpty {
                        viewModel.saveNewTask(title: newTaskTitle, priority: newTaskPriority)
                        resetNewTask()
                    }
                },
                onCancel: {
                    showPrioritySelection = false
                }
            )
            .transition(.scale)
            .padding(.bottom, 20)
        }
    }

    private var bottomBarContainer: some View {
        Group {
            if !isSearchActive && !isKeyboardVisible && !isAddingNewTask {
                VStack {
                    Spacer()
                    bottomBarView
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 2.2)))
                        .padding(.bottom, 60)
                }
            }
        }
    }

    private var bottomBarView: some View {
        BottomBar(
            onAddTap: {
                if let selectedCategory = selectedCategory {
                    viewModel.selectedCategory = selectedCategory
                }
                isAddingNewTask = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isNewTaskFocused = true
                }
            },
            isSelectionMode: $viewModel.isSelectionMode,
            selectedTasks: $viewModel.selectedTasks,
            onDeleteSelectedTasks: {
                showingDeleteAlert = true
            },
            onChangePriorityForSelectedTasks: {
                showingPrioritySheet = true
            },
            onArchiveTapped: {
                generateHapticFeedback()
                viewModel.showCompletedTasksOnly.toggle()
            },
            onUnarchiveSelectedTasks: {
                viewModel.unarchiveSelectedTasks()
            },
            showCompletedTasksOnly: $viewModel.showCompletedTasksOnly,
            onFlagSelectedTasks: {
                selectedDeadlineDate = Date()
                showingDeadlinePicker = true
            },
            onCalendarSelectedTasks: {
                selectedTargetDate = Date()
                showingDatePicker = true
            }
        )
    }

    private var priorityActionSheet: ActionSheet {
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
                .cancel(Text("Отмена")),
            ]
        )
    }

    private var transferTaskSheet: some View {
        TransferTaskView(
            selectedDate: $selectedTargetDate,
            isPresented: $showingDatePicker,
            selectedTasksCount: viewModel.selectedTasks.count,
            onMoveTasksToDate: { date in
                viewModel.moveSelectedTasksToDate(date)
            }
        )
    }

    private var deadlineTaskSheet: some View {
        DeadlineForTaskView(
            selectedDate: $selectedDeadlineDate,
            isPresented: $showingDeadlinePicker,
            selectedTasksCount: viewModel.selectedTasks.count,
            selectedTasks: getSelectedTasksInfo(),
            onSetDeadlineForTasks: { date in
                viewModel.setDeadlineForSelectedTasks(date)
            },
            existingDeadline: getExistingDeadlineForSelectedTasks()
        )
        .onAppear {
            if let existingDeadline = getExistingDeadlineForSelectedTasks() {
                selectedDeadlineDate = existingDeadline
            } else {
                selectedDeadlineDate = Date()
            }
        }
    }

    // Добавляем новый метод для получения информации о выбранных задачах
    private func getSelectedTasksInfo() -> [SelectedTaskInfo] {
        return viewModel.items
            .filter { viewModel.selectedTasks.contains($0.id) }
            .map { task in
                SelectedTaskInfo(
                    id: task.id,
                    title: task.title,
                    priority: task.priority
                )
            }
    }

    // Добавляем вспомогательный метод для получения существующего deadline
    private func getExistingDeadlineForSelectedTasks() -> Date? {
        // Получаем deadline'ы всех выбранных задач
        let selectedTaskItems = viewModel.items.filter { viewModel.selectedTasks.contains($0.id) }
        let deadlines = selectedTaskItems.compactMap { $0.deadline }

        // Если у всех задач одинаковый deadline, используем его
        if !deadlines.isEmpty
            && deadlines.allSatisfy({ Calendar.current.isDate($0, inSameDayAs: deadlines.first!) })
        {
            return deadlines.first
        }

        // Если deadline'ы разные или нет ни одного, возвращаем nil
        return nil
    }

    // MARK: - Helper Methods

    private func setupInitialState() {
        if let selectedCategory = selectedCategory {
            viewModel.selectedCategory = selectedCategory
        }
        viewModel.refreshData()
    }

    private func resetNewTask() {
        newTaskTitle = ""
        newTaskPriority = .none
        isAddingNewTask = false
        isNewTaskFocused = false
    }
}

#Preview {
    TaskListView(viewModel: ListViewModel(), selectedCategory: nil, selectedDate: .constant(Date()))
}
