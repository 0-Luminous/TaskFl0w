import Foundation

enum TaskPriority: Int, Codable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3
    
    var description: String {
        switch self {
        case .none:
            return "Нет"
        case .low:
            return "Низкий"
        case .medium:
            return "Средний"
        case .high:
            return "Высокий"
        }
    }
} 