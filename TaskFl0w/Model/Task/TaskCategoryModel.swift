import SwiftUI
import Foundation

struct TaskCategoryModel: Identifiable, Equatable, Hashable {
    let id: UUID
    let rawValue: String
    let iconName: String
    let color: Color
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(rawValue)
        hasher.combine(iconName)
        // color не хешируем, чтобы избежать ошибок.
    }
    
    static func ==(lhs: TaskCategoryModel, rhs: TaskCategoryModel) -> Bool {
        // Можно сравнивать color, если хотите
        // Но Color не Equatable "из коробки", поэтому
        // чаще сравнивают только остальные поля
        return lhs.id == rhs.id
            && lhs.rawValue == rhs.rawValue
            && lhs.iconName == rhs.iconName
    }
}
