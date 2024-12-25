import SwiftUI
import Foundation

struct TaskCategoryModel: Identifiable, Equatable {
    let id: UUID
    let rawValue: String
    let iconName: String
    let color: Color
    
    // Для удобства можно сделать статический метод для создания "заготовок" категорий,
    // если вам нужно предопределённое множество.
    // Например:
    // static let defaultCategories: [TaskCategoryModel] = [..., ..., ...]
}
