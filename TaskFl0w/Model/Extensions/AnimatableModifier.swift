import SwiftUI

struct SafeAnimatableModifier: AnimatableModifier {
    private var value: CGFloat
    
    init(value: CGFloat) {
        self.value = value.isFinite ? value : 0
    }
    
    var animatableData: CGFloat {
        get { value }
        set { value = newValue.isFinite ? newValue : 0 }
    }
    
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func safeAnimation(_ value: CGFloat) -> some View {
        modifier(SafeAnimatableModifier(value: value))
    }
} 