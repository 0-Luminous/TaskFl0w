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

    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var searchText: String = ""
    @State private var isSearchActive: Bool = false

    // Фильтрация задач по поисковому тексту
    private var filteredItems: [ToDoItem] {
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
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

    // Получаем уникальные даты из задач
    private var uniqueDates: [Date] {
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
                        ForEach(uniqueDates, id: \.self) { date in
                            Button(action: {
                                // Здесь можно добавить фильтрацию по дате
                            }) {
                                VStack(spacing: 4) {
                                    Text(date.formatted(.dateTime.day()))
                                        .font(.system(size: 20, weight: .bold))
                                    Text(date.formatted(.dateTime.month(.abbreviated)))
                                        .font(.system(size: 14))
                                }
                                .frame(width: 60)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.isDarkMode ? 
                                            Color(red: 0.18, green: 0.18, blue: 0.18) : 
                                            Color(red: 0.9, green: 0.9, blue: 0.9))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(width: 80)
                .background(
                    themeManager.isDarkMode ? 
                        Color(red: 0.13, green: 0.13, blue: 0.13) : 
                        Color(red: 0.95, green: 0.95, blue: 0.95)
                )

                // Основной контент
                VStack(spacing: 0) {
                    ScrollView {
                        Spacer()
                            .frame(height: 60)

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
                                                        categoryColor.opacity(0.7),
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
                .background(
                    themeManager.isDarkMode ? 
                        Color(red: 0.13, green: 0.13, blue: 0.13) : 
                        Color(red: 0.9, green: 0.9, blue: 0.9)
                )
            }

            // SearchBar поверх всего контента
            SearchBar(text: $searchText, isActive: $isSearchActive)
                .padding(.top, 8)
                .padding(.horizontal, 12)
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
}
