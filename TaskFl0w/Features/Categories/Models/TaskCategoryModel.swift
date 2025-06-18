import SwiftUI
import Foundation

struct TaskCategoryModel: Identifiable, Equatable, Hashable {
    let id: UUID
    let rawValue: String
    let iconName: String
    let color: Color
    let isHidden: Bool
    
    // Обновляем инициализатор, добавляя параметр isHidden с значением по умолчанию
    init(id: UUID, rawValue: String, iconName: String, color: Color, isHidden: Bool = false) {
        self.id = id
        self.rawValue = rawValue
        self.iconName = iconName
        self.color = color
        self.isHidden = isHidden
    }
}
