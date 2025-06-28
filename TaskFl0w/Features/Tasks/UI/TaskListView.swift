//
//  TaskListView.swift - OPTIMIZED with SMOOTH TASK MOVEMENT ANIMATION
//  TaskFl0w
//
//  Beautiful task movement animations by Senior iOS Developer
//

import CoreData
import SwiftUI
import UIKit
import Combine

struct TaskListView: View {
    // MARK: - Core Properties
    let selectedCategory: TaskCategoryModel?
    let hapticsManager = HapticsManager.shared

    @Binding var selectedDate: Date
    @ObservedObject var viewModel: ListViewModel
    
    // MARK: - State Management (OPTIMIZED)
    @State private var showingAddForm = false
    @State private var isSearchActive = false
    @State private var newTaskTitle = ""
    @State private var isAddingNewTask = false
    @State private var isKeyboardVisible = false
    @State private var showingPrioritySheet = false
    @State private var newTaskPriority: TaskPriority = .none
    @State private var showPrioritySelection = false
    @State private var showingDatePicker = false
    @State private var selectedTargetDate = Date()
    @State private var showingDeadlinePicker = false
    @State private var selectedDeadlineDate = Date()
    @State private var showingDeleteAlert = false

    @FocusState private var isNewTaskFocused: Bool

    // MARK: - Observed Objects (CACHED)
    @StateObject private var calendarState = CalendarState.shared
    @StateObject private var themeManager = ThemeManager.shared

    private let topID = "top_of_list"

    var body: some View {
        ZStack(alignment: .top) {
            // ОПТИМИЗАЦИЯ: Упрощенный фон
            backgroundView

            VStack(spacing: 0) {
                // 🎨 ГЛАВНАЯ ФИШКА: Основной скролл с анимацией перемещения задач
                animatedTaskListView
            }
            
            // ОПТИМИЗАЦИЯ: Условные оверлеи с анимациями
            if viewModel.showCompletedTasksOnly {
                archiveOverlayView
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
            
            if isAddingNewTask {
                newTaskOverlayView
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
            }
            
            // ОПТИМИЗАЦИЯ: Нижний бар с анимацией
            if shouldShowBottomBar {
                VStack {
                    Spacer()
                    optimizedBottomBar
                        .padding(.bottom, 60)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .scrollContentBackground(.hidden)
        .onReceive(keyboardPublisher) { isVisible in
            withAnimation(.easeInOut(duration: 0.3)) {
                isKeyboardVisible = isVisible
            }
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            handleDateChangeOptimized(newValue)
        }
        .sheet(isPresented: $showingDatePicker) {
            transferTaskSheet
        }
        .sheet(isPresented: $showingDeadlinePicker) {
            deadlineTaskSheet
        }
        .actionSheet(isPresented: $showingPrioritySheet) {
            optimizedPriorityActionSheet
        }
        .alert("Удаление задач", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    viewModel.deleteSelectedTasks()
                }
            }
        } message: {
            Text("Вы уверены, что хотите удалить выбранные задачи (\(viewModel.selectedTasks.count))?")
        }
    }
}

// MARK: - PERFORMANCE Extensions

extension TaskListView {
    
    // ОПТИМИЗАЦИЯ: Вычисляемые свойства с кешированием
    private var backgroundView: some View {
        Rectangle()
            .fill(themeManager.backgroundColor)
            .ignoresSafeArea()
    }

    private var shouldShowBottomBar: Bool {
        !isSearchActive && !isKeyboardVisible && !isAddingNewTask
    }
    
    // 🎨 КРАСИВАЯ АНИМАЦИЯ: Основной список с плавным перемещением задач
    private var animatedTaskListView: some View {
        ScrollViewReader { scrollProxy in
            List {
                listHeaderSection
                calendarSpacerSection
                
                // 🎨 ГЛАВНАЯ ФИШКА: Единый список с сортировкой для плавного перемещения
                if viewModel.showCompletedTasksOnly {
                    // Архивный режим - показываем только завершенные
                    let archivedItems = viewModel.getAllArchivedItems()
                    archivedTasksSection(items: archivedItems)
                } else {
                    // 🎨 АНИМАЦИЯ ПЕРЕМЕЩЕНИЯ: Все задачи в одной секции, сортированные по статусу
                    let allItems = getSortedTasksForAnimation()
                    allTasksSection(items: allItems)
                }
                
                newTaskSectionIfNeeded
                bottomSpacerSection
            }
            .listStyle(.grouped)
            // 🎨 КЛЮЧЕВАЯ АНИМАЦИЯ: Плавное перемещение при изменении порядка задач
            .animation(.spring(response: 0.8, dampingFraction: 0.75, blendDuration: 0.3), value: getSortedTasksForAnimation().map { "\($0.id)_\($0.isCompleted)" })
            .animation(.easeInOut(duration: 0.3), value: viewModel.showCompletedTasksOnly)
            .onAppear(perform: setupInitialState)
            .onChange(of: isAddingNewTask) { _, newValue in
                if newValue {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        scrollProxy.scrollTo("new_task_input", anchor: .bottom)
                    }
                }
            }
        }
    }

    // 🎨 КЛЮЧЕВАЯ ФУНКЦИЯ: Сортировка задач для плавной анимации перемещения
    private func getSortedTasksForAnimation() -> [ToDoItem] {
        let items = viewModel.showCompletedTasksOnly 
            ? viewModel.getAllArchivedItems()
            : viewModel.getFilteredItems()
        
        // 🎨 ВАЖНО: Сортируем так, чтобы незавершенные были сверху, завершенные - снизу
        // Это обеспечивает плавное "скольжение" вниз при завершении задачи
        return items.sorted { task1, task2 in
            // Первичная сортировка по статусу завершения
            if task1.isCompleted != task2.isCompleted {
                return !task1.isCompleted && task2.isCompleted // незавершенные сверху
            }
            
            // Вторичная сортировка по приоритету внутри группы
            if task1.priority != task2.priority {
                return task1.priority.rawValue > task2.priority.rawValue
            }
            
            // Третичная сортировка по дате создания
            return task1.date < task2.date
        }
    }

    // ОПТИМИЗАЦИЯ: Архивный оверлей
    private var archiveOverlayView: some View {
        VStack {
            ArchiveView()
            Spacer()
        }
    }

    // ОПТИМИЗАЦИЯ: Оверлей новой задачи
    private var newTaskOverlayView: some View {
        VStack {
            Spacer().frame(height: UIScreen.main.bounds.height * 0.32)

            PrioritySelectionView(
                selectedPriority: $newTaskPriority,
                onSave: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showPrioritySelection = false
                        if !newTaskTitle.isEmpty {
                            viewModel.saveNewTask(title: newTaskTitle, priority: newTaskPriority)
                            resetNewTask()
                        }
                    }
                },
                onCancel: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showPrioritySelection = false
                    }
                }
            )
            .padding(.bottom, 20)
        }
    }

    // ОПТИМИЗАЦИЯ: Нижний бар
    private var optimizedBottomBar: some View {
        BottomBar(
            onAddTap: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    handleAddTask()
                }
            },
            isSelectionMode: Binding(
                get: { viewModel.isSelectionMode },
                set: { _ in viewModel.handle(.toggleSelectionMode) }
            ),
            selectedTasks: Binding(
                get: { viewModel.selectedTasks },
                set: { _ in /* Изменения управляются через toggleTaskSelection */ }
            ),
            onDeleteSelectedTasks: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingDeleteAlert = true
                }
            },
            onChangePriorityForSelectedTasks: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingPrioritySheet = true
                }
            },
            onArchiveTapped: {
                hapticsManager.triggerMediumFeedback()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    viewModel.handle(.showCompletedTasks(!viewModel.showCompletedTasksOnly))
                }
            },
            onUnarchiveSelectedTasks: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    viewModel.unarchiveSelectedTasks()
                }
            },
            showCompletedTasksOnly: Binding(
                get: { viewModel.showCompletedTasksOnly },
                set: { _ in /* Управляется через onArchiveTapped */ }
            ),
            onFlagSelectedTasks: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedDeadlineDate = Date()
                    showingDeadlinePicker = true
                }
            },
            onCalendarSelectedTasks: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTargetDate = Date()
                    showingDatePicker = true
                }
            }
        )
    }

    // ОПТИМИЗАЦИЯ: Упрощенный ActionSheet
    private var optimizedPriorityActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Выберите приоритет"),
            buttons: [
                .default(Text("Высокий")) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        viewModel.setPriorityForSelectedTasks(.high)
                    }
                },
                .default(Text("Средний")) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        viewModel.setPriorityForSelectedTasks(.medium)
                    }
                },
                .default(Text("Низкий")) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        viewModel.setPriorityForSelectedTasks(.low)
                    }
                },
                .default(Text("Нет")) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        viewModel.setPriorityForSelectedTasks(.none)
                    }
                },
                .cancel()
            ]
        )
    }

    // ОПТИМИЗАЦИЯ: Листы для перемещения задач
    private var transferTaskSheet: some View {
        TransferTaskView(
            selectedDate: $selectedTargetDate,
            isPresented: $showingDatePicker,
            selectedTasksCount: viewModel.selectedTasks.count,
            onMoveTasksToDate: { date in
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    viewModel.moveSelectedTasksToDate(date)
                }
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
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    viewModel.setDeadlineForSelectedTasks(date)
                }
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

    // ОПТИМИЗАЦИЯ: Издатели для debouncing
    private var keyboardPublisher: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                .map { _ in true },
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false }
        )
        .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    // ОПТИМИЗАЦИЯ: Методы для обработки событий
    private func handleDateChangeOptimized(_ newDate: Date) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if selectedDate == newDate {
                withAnimation(.easeInOut(duration: 0.4)) {
                    viewModel.selectedDate = newDate
                    viewModel.handle(.loadTasks(newDate))
                }
            }
        }
    }
    
    private func setupInitialState() {
        if let selectedCategory = selectedCategory {
            viewModel.selectedCategory = selectedCategory
        }
        viewModel.handle(.loadTasks(Date()))
    }
    
    private func handleAddTask() {
        if let selectedCategory = selectedCategory {
            viewModel.selectedCategory = selectedCategory
        }
        isAddingNewTask = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isNewTaskFocused = true
        }
    }
    
    private func resetNewTask() {
        newTaskTitle = ""
        newTaskPriority = .none
        isAddingNewTask = false
        isNewTaskFocused = false
    }
    
    // Вспомогательные методы
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

    private func getExistingDeadlineForSelectedTasks() -> Date? {
        let selectedTaskItems = viewModel.items.filter { viewModel.selectedTasks.contains($0.id) }
        let deadlines = selectedTaskItems.compactMap { $0.deadline }

        if !deadlines.isEmpty && deadlines.allSatisfy({ Calendar.current.isDate($0, inSameDayAs: deadlines.first!) }) {
            return deadlines.first
        }

        return nil
    }
}

// MARK: - Optimized Sections

extension TaskListView {
    
    // ОПТИМИЗАЦИЯ: Разделение на секции с @ViewBuilder
    @ViewBuilder
    private var listHeaderSection: some View {
        EmptyView()
            .id(topID)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
        
        if viewModel.showCompletedTasksOnly {
            Color.clear
                .frame(height: 20)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
    
    @ViewBuilder
    private var calendarSpacerSection: some View {
        if calendarState.isWeekCalendarVisible {
            Color.clear
                .frame(height: 70)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .transition(.slide.combined(with: .opacity))
        }
        
        if calendarState.isMonthCalendarVisible {
            Color.clear
                .frame(height: 300)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .transition(.slide.combined(with: .opacity))
        }
    }
    
    @ViewBuilder
    private var newTaskSectionIfNeeded: some View {
        if isAddingNewTask {
            TaskInput(
                newTaskTitle: $newTaskTitle,
                isNewTaskFocused: _isNewTaskFocused,
                selectedPriority: $newTaskPriority,
                onSave: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        viewModel.saveNewTask(title: newTaskTitle, priority: newTaskPriority)
                        resetNewTask()
                    }
                }
            )
            .id("new_task_input")
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            ))
        }
    }
    
    private var bottomSpacerSection: some View {
        Color.clear
            .frame(height: 160)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
    
    // ОПТИМИЗАЦИЯ: Архивные задачи
    private func archivedTasksSection(items: [ToDoItem]) -> some View {
        ArchivedTasksGroupView(
            items: items,
            categoryColor: viewModel.selectedCategory?.color ?? .blue,
            isSelectionMode: viewModel.isSelectionMode,
            selectedTasks: .constant(viewModel.selectedTasks),
            onToggle: { taskId in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.handle(.toggleTaskCompletion(taskId))
                }
            },
            onEdit: { item in
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.handle(.editTask(item))
                }
            },
            onDelete: { taskId in
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    viewModel.handle(.deleteTask(taskId))
                }
            },
            onShare: { taskId in
                // TODO: Реализуем sharing
            }
        )
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    // 🎨 ГЛАВНАЯ ФУНКЦИЯ: Все задачи в одной секции для плавной анимации перемещения
    @ViewBuilder
    private func allTasksSection(items: [ToDoItem]) -> some View {
        ForEach(items) { item in
            TaskRow(
                item: item,
                onToggle: {
                    // 🎨 КРАСИВАЯ АНИМАЦИЯ: Плавное "скольжение" задачи при завершении
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.3)) {
                        hapticsManager.triggerMediumFeedback()
                        viewModel.handle(.toggleTaskCompletion(item.id))
                    }
                },
                onEdit: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.handle(.editTask(item))
                    }
                },
                onDelete: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        hapticsManager.triggerMediumFeedback()
                        viewModel.handle(.deleteTask(item.id))
                    }
                },
                onShare: {
                    // TODO: Реализуем sharing
                },
                categoryColor: viewModel.selectedCategory?.color ?? .blue,
                isSelectionMode: viewModel.isSelectionMode,
                isInArchiveMode: viewModel.showCompletedTasksOnly,
                selectedTasks: .constant(viewModel.selectedTasks)
            )
            .padding(.trailing, 5)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
            .contentShape(Rectangle())
            // 🎨 УНИКАЛЬНЫЙ ID: Для правильной анимации перемещения
            .id("\(item.id.uuidString)_\(item.isCompleted ? "completed" : "active")")
            .onTapGesture {
                if viewModel.isSelectionMode {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        hapticsManager.triggerLightFeedback()
                        viewModel.toggleTaskSelection(taskId: item.id)
                    }
                } else {
                    // 🎨 КЛЮЧЕВАЯ АНИМАЦИЯ: Плавное перемещение при тапе
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.3)) {
                        hapticsManager.triggerMediumFeedback()
                        viewModel.handle(.toggleTaskCompletion(item.id))
                    }
                }
            }
            .listRowSeparator(.hidden)
        }
    }
}

// MARK: - Performance Extensions

extension ThemeManager {
    var backgroundColor: Color {
        isDarkMode 
            ? Color(red: 0.098, green: 0.098, blue: 0.098)
            : Color(red: 0.95, green: 0.95, blue: 0.95)
    }
}
