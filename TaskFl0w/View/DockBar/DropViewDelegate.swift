//
//  DropViewDelegate.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct DropViewDelegate: DropDelegate {
    let item: TaskCategoryModel
    @Binding var items: [TaskCategoryModel]
    @Binding var draggedItem: TaskCategoryModel?

    func performDrop(info: DropInfo) -> Bool {
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedItem = self.draggedItem,
              let fromIndex = items.firstIndex(of: draggedItem),
              let toIndex = items.firstIndex(of: item),
              draggedItem != item else { return }
        
        withAnimation(.default) {
            items.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
    }
}
