//
//  ArchiveView.swift
//  TaskFl0w
//
//  Created by Yan on 30/4/25.
//

import SwiftUI

struct ArchiveView: View {

    @ObservedObject private var themeManager = ThemeManager.shared
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.clear)
                .frame(height: 50) // Небольшой отступ сверху
            
            HStack {
                Image(systemName: "archivebox.fill")
                    .foregroundColor(themeManager.isDarkMode ? .coral1 : .red1)
                    .font(.system(size: 16))
                
                Text("Архив выполненных задач")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .background {
                // Размытый фон
                Capsule()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, themeManager.isDarkMode ? .dark : .light)
                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // Функция для фильтрации и сортировки архивных задач
    static func getFilteredArchivedItems(from items: [ToDoItem], selectedCategoryID: UUID?) -> [ToDoItem] {
        var filteredItems: [ToDoItem]
        
        // Сначала фильтруем по категории, если она выбрана
        if let selectedCategoryID = selectedCategoryID {
            filteredItems = items.filter { item in
                item.categoryID == selectedCategoryID
            }
        } else {
            filteredItems = items
        }
        
        // Фильтруем только завершенные задачи
        filteredItems = filteredItems.filter { item in
            item.isCompleted
        }
        
        // Сортируем задачи
        return filteredItems.sorted { (item1, item2) -> Bool in
            // Сначала сортируем по приоритету
            if item1.priority != item2.priority {
                return item1.priority.rawValue > item2.priority.rawValue
            }
            
            // Если приоритеты одинаковые, сортируем по дате завершения
            // (от новых к старым)
            return item1.date > item2.date
        }
    }
}

#Preview {
    ArchiveView()
        .background(Color(red: 0.098, green: 0.098, blue: 0.098))
}

