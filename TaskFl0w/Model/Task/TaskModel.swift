import SwiftUI
import Foundation

struct Task: Identifiable, Equatable {
    let id: UUID
    var title: String
    var startTime: Date
    var duration: TimeInterval
    var color: Color
    var icon: String
    var category: TaskCategoryModel
    var isCompleted: Bool
    
    // Можно добавлять дополнительные поля, методы и т.д.
}
