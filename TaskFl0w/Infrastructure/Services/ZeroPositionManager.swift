import SwiftUI

final class ZeroPositionManager: ObservableObject {
    static let shared = ZeroPositionManager()
    
    @Published var zeroPosition: Double {
        didSet {
            UserDefaults.standard.set(zeroPosition, forKey: "zeroPosition")
            NotificationCenter.default.post(name: .zeroPositionDidChange, object: nil)
        }
    }
    
    private init() {
        self.zeroPosition = UserDefaults.standard.double(forKey: "zeroPosition")
    }
    
    func updateZeroPosition(_ newPosition: Double) {
        zeroPosition = newPosition
    }
}

extension Notification.Name {
    static let zeroPositionDidChange = Notification.Name("zeroPositionDidChange")
} 