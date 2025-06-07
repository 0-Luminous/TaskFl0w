//
//  SearchView.swift
//  TaskFl0w
//
//  Created by Yan on 26/5/25.
//

import SwiftUI

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
    @Environment(\.dismiss) private var dismiss

    // Фильтрация задач по поисковому тексту и дате
    private var filteredItems: [ToDoItem] {
        let dateFiltered = selectedDate == nil ? items : items.filter { 
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate!)
        }
        
        if searchText.isEmpty {
            return dateFiltered
        } else {
            return dateFiltered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }

    // Группировка задач по категориям
    private var groupedTasks: [String: [ToDoItem]] {
        Dictionary(grouping: filteredItems) { item in
            item.categoryName ?? "Без категории"
        }
    }

    private var sortedCategories: [String] {
        groupedTasks.keys.sorted()
    }

    // Получаем уникальные даты из всех задач (независимо от фильтра)
    private var allUniqueDates: [Date] {
        Array(Set(items.map { Calendar.current.startOfDay(for: $0.date) })).sorted(by: >)
    }

    // Получаем уникальные даты из отфильтрованных задач
    private var filteredUniqueDates: [Date] {
        Array(Set(filteredItems.map { Calendar.current.startOfDay(for: $0.date) })).sorted(by: >)
    }

    var body: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 0) {
                // Левая панель с датами
                ScrollView {
                    Spacer()
                        .frame(height: 60)
                    VStack(spacing: 12) {
                        ForEach(allUniqueDates, id: \.self) { date in
                            Button(action: {
                                if selectedDate == date {
                                    selectedDate = nil
                                } else {
                                    selectedDate = date
                                }
                            }) {
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
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(themeManager.isDarkMode ? 
                                                Color(red: 0.18, green: 0.18, blue: 0.18) : 
                                                Color(red: 0.9, green: 0.9, blue: 0.9))
                                        
                                        // Синий бордер для выбранной даты
                                        if Calendar.current.isDate(date, inSameDayAs: selectedDate ?? Date.distantPast) {
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue, lineWidth: 1)
                                        }
                                    }
                                )
                                .padding(.horizontal, 2)
                                .opacity(filteredUniqueDates.contains(date) ? 1.0 : 0.2) // Затемняем неактивные даты
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
                .scrollIndicators(.hidden)
                .frame(width: 80)
                .background(
                    themeManager.isDarkMode ? 
                        Color(red: 0.1, green: 0.1, blue: 0.1) : 
                        Color(red: 0.8, green: 0.8, blue: 0.8)
                )

                // Основной контент
                VStack(spacing: 0) {
                    ScrollView {
                        Spacer()
                            .frame(height: 60)

                        if filteredItems.isEmpty {
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
                        } else {
                            ForEach(sortedCategories, id: \.self) { category in
                                if let tasksForCategory = groupedTasks[category] {
                                    VStack(spacing: 0) {
                                        // Заголовок группы с категорией
                                        HStack {
                                            Text(category)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                                            Spacer()
                                            Text("\(tasksForCategory.count)")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(themeManager.isDarkMode ? .gray : .black)
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)

                                        // Контейнер для задач группы
                                        VStack(spacing: 8) {
                                            ForEach(tasksForCategory) { item in
                                                TaskRow(
                                                    item: item,
                                                    onToggle: { onToggle(item.id) },
                                                    onEdit: { onEdit(item) },
                                                    onDelete: { onDelete(item.id) },
                                                    onShare: { onShare(item.id) },
                                                    categoryColor: categoryColor,
                                                    isSelectionMode: isSelectionMode,
                                                    isInArchiveMode: false,  // или true, если нужно
                                                    selectedTasks: $selectedTasks
                                                )
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 3)
                                                .background(
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill(
                                                                themeManager.isDarkMode
                                                                    ? Color(
                                                                        red: 0.18, green: 0.18, blue: 0.18)
                                                                    : Color(red: 0.9, green: 0.9, blue: 0.9)
                                                            )
                                                            .shadow(
                                                                color: .black.opacity(0.3), radius: 3, x: 0,
                                                                y: 1)
                                                        if item.priority != .none {
                                                            RoundedRectangle(cornerRadius: 10)
                                                                .stroke(
                                                                    getPriorityColor(for: item.priority),
                                                                    lineWidth: 1.5
                                                                )
                                                                .opacity(0.3)
                                                        }
                                                    }
                                                )
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    if isSelectionMode {
                                                        if selectedTasks.contains(item.id) {
                                                            selectedTasks.remove(item.id)
                                                        } else {
                                                            selectedTasks.insert(item.id)
                                                        }
                                                    } else {
                                                        onToggle(item.id)
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, 10)
                                        }
                                        .padding(.vertical, 16)
                                    }
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(
                                                    themeManager.isDarkMode
                                                        ? Color(red: 0.13, green: 0.13, blue: 0.13)
                                                        : Color(red: 0.9, green: 0.9, blue: 0.9)
                                                )
                                                .shadow(
                                                    color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [
                                                            getCategoryColor(for: category),
                                                            Color.gray.opacity(0.6),
                                                        ]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1.5
                                                )
                                        }
                                    )
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 10)
                                    .simultaneousGesture(TapGesture().onEnded {})
                                }
                            }
                        }
                    }
                }
                .background(
                    themeManager.isDarkMode ? 
                        Color(red: 0.13, green: 0.13, blue: 0.13) : 
                        Color(red: 0.9, green: 0.9, blue: 0.9)
                )
            }

            // Верхняя панель с кнопкой выхода и поиском
            HStack(spacing: 8) {
                // Кнопка выхода
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? .coral1 : .red1)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(themeManager.isDarkMode ? 
                                    Color(red: 0.18, green: 0.18, blue: 0.18) : 
                                    Color(red: 0.9, green: 0.9, blue: 0.9))
                        )
                }
                .padding(.leading, 10)

                SearchBar(text: $searchText, isActive: $isSearchActive)
                .padding(.leading, 20)
            }
            .padding(.top, 8)
            .padding(.horizontal, 10)
            .zIndex(1)
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
        if let category = categoryManagement.categories.first(where: { $0.rawValue == categoryName }) {
            return category.color
        }
        return categoryColor // Используем переданный цвет как запасной вариант
    }
}
