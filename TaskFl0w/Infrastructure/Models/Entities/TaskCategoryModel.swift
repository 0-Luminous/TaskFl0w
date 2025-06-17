import SwiftUI
import Foundation

struct TaskCategoryModel: Identifiable, Equatable, Hashable {
    let id: UUID
    let rawValue: String
    let iconName: String
    let color: Color
    var order: Int
    var isHidden: Bool = false
    
    // Обновляем инициализатор
    init(id: UUID = UUID(), rawValue: String, iconName: String, color: Color, order: Int = 0, isHidden: Bool = false) {
        self.id = id
        self.rawValue = rawValue
        self.iconName = iconName
        self.color = color
        self.order = order
        self.isHidden = isHidden
    }
}
