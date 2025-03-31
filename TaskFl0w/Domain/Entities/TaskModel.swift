import Foundation
import SwiftUI

struct TaskOnRing: Identifiable, Hashable {
    let id: UUID
    var title: String
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

    // Можно добавлять дополнительные поля, методы и т.д.
}
