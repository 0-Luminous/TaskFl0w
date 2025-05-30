//
//  CategoryDropDelegate.swift
//  TaskFl0w
//
//  Created by Yan on 14/4/25.
//
import SwiftUI
// Новый делегат для обработки перетаскивания
struct CategoryDropDelegate: DropDelegate {
    let item: TaskCategoryModel
    let items: [TaskCategoryModel]
    let draggedItem: TaskCategoryModel?
    let moveAction: (Int, Int) -> Void

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedItem = draggedItem else { 
            print("🔄 DEBUG: CategoryDropDelegate - no draggedItem")
            return false 
        }

        let fromIndex = items.firstIndex(of: draggedItem) ?? 0
        let toIndex = items.firstIndex(of: item) ?? 0

        // Только если перетаскиваем между разными категориями
        if fromIndex != toIndex {
            print("📦 DEBUG: Moving category from \(fromIndex) to \(toIndex)")
            moveAction(fromIndex, toIndex)
            return true
        }
        
        print("⚠️ DEBUG: CategoryDropDelegate - same position, returning false")
        return false  // Возвращаем false если позиция не изменилась
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func validateDrop(info: DropInfo) -> Bool {
        return true
    }
}
