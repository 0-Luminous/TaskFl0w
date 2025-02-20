import SwiftUI

extension ClockStyle: RawRepresentable {
    public init?(rawValue: String) {
        switch rawValue {
        case "classic":
            self = .classic
        case "minimal":
            self = .minimal
        case "modern":
            self = .modern
        default:
            return nil
        }
    }
    
    public var rawValue: String {
        switch self {
        case .classic:
            return "classic"
        case .minimal:
            return "minimal"
        case .modern:
            return "modern"
        }
    }
} 