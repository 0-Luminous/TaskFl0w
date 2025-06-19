//
//  CategoryButtonContent.swift
//  TaskFl0w
//
//  Created by Yan on 14/4/25.
//
import SwiftUI
import UIKit

// Новая структура для содержимого кнопки категории
struct CategoryButtonContent: View {
    let category: TaskCategoryModel
    let categories: [TaskCategoryModel]
    let isSelected: Bool
    let categoryWidth: CGFloat
    let moveCategory: (Int, Int) -> Void
    let hapticsManager = HapticsManager.shared

    @ObservedObject var themeManager: ThemeManager
    
    @Binding var selectedCategory: TaskCategoryModel?
    @Binding var draggedCategory: TaskCategoryModel?
    

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
            hapticsManager.triggerLightFeedback()
            
            withAnimation {
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
            print("🚀 DEBUG: onDrag started for category: \(category.rawValue)")
            draggedCategory = category
            print("✅ DEBUG: Set draggedCategory to: \(category.rawValue)")
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
                moveAction: { fromIndex, toIndex in
                    print("📦 DEBUG: CategoryDropDelegate moveAction - from: \(fromIndex), to: \(toIndex)")
                    moveCategory(fromIndex, toIndex)
                }
            )
        )
    }
}
