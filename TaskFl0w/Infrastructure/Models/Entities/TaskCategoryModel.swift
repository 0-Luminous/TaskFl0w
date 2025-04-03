import SwiftUI
import Foundation

struct TaskCategoryModel: Identifiable, Equatable, Hashable {
    let id: UUID
    let rawValue: String
    let iconName: String
    let color: Color
}
