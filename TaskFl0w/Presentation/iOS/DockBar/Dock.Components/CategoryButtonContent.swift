//
//  CategoryButtonContent.swift
//  TaskFl0w
//
//  Created by Yan on 14/4/25.
//
import SwiftUI

// Новая структура для содержимого кнопки категории
struct CategoryButtonContent: View {
    let category: TaskCategoryModel
    let categories: [TaskCategoryModel]
    let isSelected: Bool
    @ObservedObject var themeManager: ThemeManager
    let categoryWidth: CGFloat
    @Binding var selectedCategory: TaskCategoryModel?
    @Binding var draggedCategory: TaskCategoryModel?
    let moveCategory: (Int, Int) -> Void

    var body: some View {
        CategoryButton(
            category: category,
            isSelected: isSelected,
            themeManager: themeManager
        )
        .frame(width: categoryWidth, height: 80)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onTapGesture {
            withAnimation {
                // Если выбрана та же категория - убираем её
                if selectedCategory?.id == category.id {
                    selectedCategory = nil
                } else {
                    // Если выбрана другая категория - показываем её
                    selectedCategory = category
                }
            }
        }
        .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 12))
        .onDrag {
            draggedCategory = category
            return NSItemProvider(object: category.id.uuidString as NSString)
        } preview: {
            CategoryDragPreview(task: TaskOnRing(
                id: category.id,
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                color: category.color,
                icon: category.iconName,
                category: category,
                isCompleted: false
            ))
        }
        .onDrop(
            of: [.text],
            delegate: CategoryDropDelegate(
                item: category,
                items: categories,
                draggedItem: draggedCategory,
                moveAction: moveCategory
            )
        )
    }
}
