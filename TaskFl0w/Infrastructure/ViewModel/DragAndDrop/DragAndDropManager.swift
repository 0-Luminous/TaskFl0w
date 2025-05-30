import Combine
import Foundation
import SwiftUI

final class DragAndDropManager: ObservableObject {
    // MARK: - Properties
    @Published var draggedTask: TaskOnRing?
    @Published var isDraggingOutside: Bool = false
    @Published var draggedCategory: TaskCategoryModel?
    @Published var isDraggingStart: Bool = false
    @Published var isDraggingEnd: Bool = false
    @Published var dropLocation: CGPoint?

    // MARK: - Services
    private let taskManagement: TaskManagementProtocol

    // MARK: - Initialization
    init(taskManagement: TaskManagementProtocol) {
        self.taskManagement = taskManagement
    }

    // MARK: - Task Dragging Methods
    func startDragging(_ task: TaskOnRing) {
        draggedTask = task
    }

    func stopDragging(didReturnToClock: Bool) {
        draggedTask = nil
        isDraggingOutside = false
        
        print("✅ Перетаскивание завершено, задача сохранена")
    }

    func updateDragPosition(isOutsideClock: Bool) {
        isDraggingOutside = isOutsideClock
    }
}

// MARK: - Drop Delegate
extension DragAndDropManager {
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
                draggedItem != item
            else { return }

            withAnimation(.default) {
                items.move(
                    fromOffsets: IndexSet(integer: fromIndex),
                    toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
                )
            }
        }
    }
}
