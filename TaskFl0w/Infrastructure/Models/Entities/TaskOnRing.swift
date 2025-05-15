import Foundation
import SwiftUI

struct TaskOnRing: Identifiable, Hashable, Equatable {
    let id: UUID
    var startTime: Date
    var endTime: Date
    var color: Color
    var icon: String
    var category: TaskCategoryModel
    var isCompleted: Bool

    // Вычисляемое свойство для получения продолжительности, если оно нужно
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    // Реализация Equatable
    static func == (lhs: TaskOnRing, rhs: TaskOnRing) -> Bool {
        return lhs.id == rhs.id &&
               lhs.startTime == rhs.startTime &&
               lhs.endTime == rhs.endTime &&
               lhs.isCompleted == rhs.isCompleted &&
               lhs.category.id == rhs.category.id
    }
    
    // Реализация Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(startTime)
        hasher.combine(endTime)
        hasher.combine(isCompleted)
        hasher.combine(category.id)
    }

    // Можно добавлять дополнительные поля, методы и т.д.
}
