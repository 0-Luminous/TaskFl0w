//  SearchView.swift
//  TaskFl0w
//
//  Created by Yan on 26/5/25.
//

import SwiftUI

// Перечисление для режимов фильтрации дат
enum DateFilterMode {
    case currentAndFuture  // Текущие и будущие даты
    case pastOnly         // Только прошлые даты
}

struct SearchView: View {
    let items: [ToDoItem]
    let categoryColor: Color
    let isSelectionMode: Bool
    @Binding var selectedTasks: Set<UUID>
    let onToggle: (UUID) -> Void
    let onEdit: (ToDoItem) -> Void
    let onDelete: (UUID) -> Void
    let onShare: (UUID) -> Void
    let categoryManagement: CategoryManagementProtocol

    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var searchText: String = ""
    @State private var isSearchActive: Bool = false
    @State private var selectedDate: Date? = nil
    @State private var isDatePanelVisible: Bool = false
    @State private var dateFilterMode: DateFilterMode = .currentAndFuture
    @State private var scrollID = UUID()
    @Environment(\.dismiss) private var dismiss

    // Кэшированные цвета для производительности
    private var darkModeColors: (background: Color, surface: Color, panel: Color) {
        (
            background: Color(red: 0.13, green: 0.13, blue: 0.13),
            surface: Color(red: 0.18, green: 0.18, blue: 0.18),
            panel: Color(red: 0.1, green: 0.1, blue: 0.1)
        )
    }

    private var lightModeColors: (background: Color, surface: Color, panel: Color) {
        (
            background: Color(red: 0.9, green: 0.9, blue: 0.9),
            surface: Color(red: 0.9, green: 0.9, blue: 0.9),
            panel: Color(red: 0.8, green: 0.8, blue: 0.8)
        )
    }

    // Фильтрация задач только по поисковому тексту и дате
    private var filteredItems: [ToDoItem] {
        let today = Calendar.current.startOfDay(for: Date())
        let filteredByText =
            searchText.isEmpty
            ? items : items.filter { $0.title.localizedCaseInsensitiveContains(searchText) }

        // Фильтруем по датам в зависимости от режима
        switch dateFilterMode {
        case .currentAndFuture:
            return filteredByText.filter { item in
                let itemDate = Calendar.current.startOfDay(for: item.date)
                return itemDate >= today
            }
        case .pastOnly:
            return filteredByText.filter { item in
                let itemDate = Calendar.current.startOfDay(for: item.date)
                return itemDate < today
            }
        }
    }

    // Оптимизированная группировка задач сначала по датам, затем по категориям
    private var tasksByDate:
        [(date: Date, categories: [(name: String, tasks: [ToDoItem], color: Color)])]
    {
        let today = Calendar.current.startOfDay(for: Date())
        let dateGrouped = Dictionary(grouping: filteredItems) { item in
            Calendar.current.startOfDay(for: item.date)
        }

        return dateGrouped.compactMap { (date, tasks) in
            let categoryGrouped = Dictionary(grouping: tasks) { item in
                item.categoryName ?? "Без категории"
            }

            let categories = categoryGrouped.map { (categoryName, categoryTasks) in
                (
                    name: categoryName,
                    tasks: categoryTasks,
                    color: getCategoryColor(for: categoryName)
                )
            }.sorted { $0.name < $1.name }

            return (date: date, categories: categories)
        }.sorted {
            switch dateFilterMode {
            case .pastOnly:
                return $0.date > $1.date  // При показе прошлых дат - сначала новые
            case .currentAndFuture:
                return $0.date < $1.date  // При показе текущих/будущих дат - сначала сегодня
            }
        }
    }

    // Получаем уникальные даты (только текущие и будущие)
    private var allUniqueDates: [Date] {
        tasksByDate.map { $0.date }
    }

    // Инициализация selectedDate с текущей датой
    private var currentSelectedDate: Date {
        let today = Calendar.current.startOfDay(for: Date())
        return selectedDate ?? allUniqueDates.first {
            Calendar.current.isDate($0, inSameDayAs: today)
        } ?? allUniqueDates.first ?? today
    }

    var body: some View {
        ZStack(alignment: .top) {
            mainContentWithSwipe
                .id(scrollID)

            slidingDatePanel

            if isDatePanelVisible {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isDatePanelVisible = false
                        }
                    }
                    .zIndex(1)
            }

            topPanel
        }
        .onAppear {
            scrollID = UUID()
        }
    }

    // MARK: - Компоненты интерфейса

    private var slidingDatePanel: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(allUniqueDates, id: \.self) { date in
                            DateButton(
                                date: date,
                                isSelected: Calendar.current.isDate(
                                    date, inSameDayAs: currentSelectedDate)
                            ) {
                                selectedDate = date
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isDatePanelVisible = false
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .scrollIndicators(.hidden)
            }
            .frame(width: 80)
            .background(themeManager.isDarkMode ? darkModeColors.panel : lightModeColors.panel)
            .shadow(color: .black.opacity(0.2), radius: 8, x: -2, y: 0)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let threshold: CGFloat = 30
                        if value.translation.width > threshold {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isDatePanelVisible = false
                            }
                        }
                    }
            )
        }
        .offset(x: isDatePanelVisible ? 0 : 80)
        .animation(.easeInOut(duration: 0.3), value: isDatePanelVisible)
        .zIndex(2)
    }

    private var mainContentWithSwipe: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    Spacer().frame(height: 100)
                        .id("topAnchor")

                    if filteredItems.isEmpty {
                        EmptyStateView()
                    } else {
                        LazyVStack(spacing: 20) {
                            ForEach(tasksByDate, id: \.date) { dateGroup in
                                DateSectionView(
                                    dateGroup: dateGroup,
                                    isSelectionMode: isSelectionMode,
                                    selectedTasks: $selectedTasks,
                                    onToggle: onToggle,
                                    onEdit: onEdit,
                                    onDelete: onDelete,
                                    onShare: onShare,
                                    categoryColor: categoryColor,
                                    categoryManagement: categoryManagement
                                )
                                .id(dateGroup.date)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("topAnchor", anchor: .top)
                        }
                    }
                    
                    initializeSelectedDate()
                }
                .onChange(of: selectedDate) { newDate in
                    if let targetDate = newDate {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(targetDate, anchor: .top)
                        }
                    }
                }
            }
        }
        .background(
            themeManager.isDarkMode ? darkModeColors.background : lightModeColors.background
        )
        .gesture(
            DragGesture()
                .onEnded { value in
                    let threshold: CGFloat = 50
                    let startX = value.startLocation.x
                    let screenWidth = UIScreen.main.bounds.width

                    if startX > screenWidth - 50 {
                        if value.translation.width < -threshold && !isDatePanelVisible {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isDatePanelVisible = true
                            }
                        } else if value.translation.width > threshold && isDatePanelVisible {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isDatePanelVisible = false
                            }
                        }
                    }
                }
        )
    }

    private var topPanel: some View {
        HStack(spacing: 8) {

            BackButton {
                dismiss()
            }

            SearchBar(text: $searchText, isActive: $isSearchActive)
         
            // Кнопка переключения режимов дат
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    dateFilterMode = dateFilterMode == .currentAndFuture ? .pastOnly : .currentAndFuture
                }
            }) {
                Image(systemName: clockIconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        Circle()
                            .stroke(clockBorderColor, lineWidth: 1.5)
                    )
            }
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isDatePanelVisible.toggle()
                }
            }) {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        Circle()
                            .stroke(isDatePanelVisible ? Color.blue : Color.clear, lineWidth: 2)
                    )
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 10)
        .zIndex(3)
    }

    // Вычисляемые свойства для иконки и цвета кнопки часов
    private var clockIconName: String {
        switch dateFilterMode {
        case .currentAndFuture:
            return "clock"
        case .pastOnly:
            return "clock.badge.checkmark.fill"
        }
    }

    private var clockBorderColor: Color {
        switch dateFilterMode {
        case .currentAndFuture:
            return Color.clear
        case .pastOnly:
            return Color.orange
        }
    }

    // MARK: - Вспомогательные функции

    private func initializeSelectedDate() {
        if selectedDate == nil {
            selectedDate = allUniqueDates.first
        }
    }

    private func getPriorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        case .none: return .clear
        }
    }

    private func getCategoryColor(for categoryName: String) -> Color {
        categoryManagement.categories.first { $0.rawValue == categoryName }?.color ?? categoryColor
    }
}

// MARK: - Вспомогательные компоненты

private struct DateButton: View {
    let date: Date
    let isSelected: Bool
    @ObservedObject private var themeManager = ThemeManager.shared
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(date.formatted(.dateTime.day()))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                Text(date.formatted(.dateTime.month(.abbreviated)))
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
            }
            .frame(width: 60)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        themeManager.isDarkMode
                            ? Color(red: 0.18, green: 0.18, blue: 0.18)
                            : Color(red: 0.9, green: 0.9, blue: 0.9)
                    )
                    .overlay(
                        isSelected
                            ? RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 1) : nil
                    )
            )
            .padding(.horizontal, 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct EmptyStateView: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(themeManager.isDarkMode ? .gray : .gray.opacity(0.5))
            Text("search.tasksNotFound".localized)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

private struct DateSectionView: View {
    let dateGroup: (date: Date, categories: [(name: String, tasks: [ToDoItem], color: Color)])
    @ObservedObject private var themeManager = ThemeManager.shared
    let isSelectionMode: Bool
    @Binding var selectedTasks: Set<UUID>
    let onToggle: (UUID) -> Void
    let onEdit: (ToDoItem) -> Void
    let onDelete: (UUID) -> Void
    let onShare: (UUID) -> Void
    let categoryColor: Color
    let categoryManagement: CategoryManagementProtocol

    var body: some View {
        VStack(spacing: 0) {
            DateHeaderView(
                date: dateGroup.date,
                taskCount: dateGroup.categories.flatMap { $0.tasks }.count
            )

            ForEach(dateGroup.categories, id: \.name) { category in
                CategoryContainerView(
                    category: category,
                    isSelectionMode: isSelectionMode,
                    selectedTasks: $selectedTasks,
                    onToggle: onToggle,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onShare: onShare,
                    categoryColor: categoryColor,
                    categoryManagement: categoryManagement
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    themeManager.isDarkMode
                        ? Color(red: 0.25, green: 0.25, blue: 0.25)
                        : Color(red: 0.95, green: 0.95, blue: 0.95)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 10)
    }
}

private struct DateHeaderView: View {
    let date: Date
    let taskCount: Int
    @ObservedObject private var themeManager = ThemeManager.shared

    // Расширенная функция для получения названия дня
    private func getDayName(for date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: date)

        let daysDifference = calendar.dateComponents([.day], from: today, to: targetDate).day ?? 0

        switch daysDifference {
        case -1:
            return "Вчера"
        case 0:
            return "Сегодня"
        case 1:
            return "Завтра"
        default:
            return date.formatted(.dateTime.weekday(.wide))
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Text(getDayName(for: date))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            Spacer()
            Text(date.formatted(.dateTime.day(.twoDigits).month(.abbreviated).year()))
                .font(.system(size: 14))
                .foregroundColor(themeManager.isDarkMode ? .gray : .gray)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

private struct CategoryContainerView: View {
    let category: (name: String, tasks: [ToDoItem], color: Color)
    @ObservedObject private var themeManager = ThemeManager.shared
    let isSelectionMode: Bool
    @Binding var selectedTasks: Set<UUID>
    let onToggle: (UUID) -> Void
    let onEdit: (ToDoItem) -> Void
    let onDelete: (UUID) -> Void
    let onShare: (UUID) -> Void
    let categoryColor: Color
    let categoryManagement: CategoryManagementProtocol

    // Функция для получения иконки категории
    private func getCategoryIcon(for categoryName: String) -> String {
        return categoryManagement.categories.first { $0.rawValue == categoryName }?.iconName
            ?? "folder.fill"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Название категории слева
                Text(category.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)

                Spacer()

                // Иконка категории справа
                Image(systemName: getCategoryIcon(for: category.name))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 20, height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            VStack(spacing: 8) {
                ForEach(category.tasks) { item in
                    TaskRow(
                        item: item,
                        onToggle: { onToggle(item.id) },
                        onEdit: { onEdit(item) },
                        onDelete: { onDelete(item.id) },
                        onShare: { onShare(item.id) },
                        categoryColor: categoryColor,
                        isSelectionMode: isSelectionMode,
                        isInArchiveMode: false,
                        selectedTasks: $selectedTasks
                    )
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(
                        TaskRowBackground(priority: item.priority)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleTaskTap(item.id)
                    }
                }
                .padding(.horizontal, 10)
            }
            .padding(.vertical, 16)
        }
        .background(
            CategoryBackground(color: category.color)
        )
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
    }

    private func handleTaskTap(_ itemId: UUID) {
        if isSelectionMode {
            if selectedTasks.contains(itemId) {
                selectedTasks.remove(itemId)
            } else {
                selectedTasks.insert(itemId)
            }
        } else {
            onToggle(itemId)
        }
    }
}

private struct TaskRowBackground: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let priority: TaskPriority

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    themeManager.isDarkMode
                        ? Color(red: 0.18, green: 0.18, blue: 0.18)
                        : Color(red: 0.9, green: 0.9, blue: 0.9)
                )
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)

            if priority != .none {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(getPriorityColor(for: priority), lineWidth: 1.5)
                    .opacity(0.3)
            }
        }
    }

    private func getPriorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        case .none: return .clear
        }
    }
}

private struct CategoryBackground: View {
    let color: Color
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            color,
                            color.opacity(0.8),
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)

            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.5),
                            Color.gray.opacity(0.3),
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
    }
}

private struct BackButton: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.backward")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? .coral1 : .red1)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
        }
        .padding(.leading, 10)
    }
}
