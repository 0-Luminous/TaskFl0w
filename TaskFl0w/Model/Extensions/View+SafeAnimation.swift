import SwiftUI

struct ClockAnimatableModifier: AnimatableModifier {
    private var angle: Double
    private var radius: Double
    
    init(angle: Double, radius: Double) {
        self.angle = angle
        self.radius = radius
    }
    
    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(Angle(degrees: angle))
            .offset(x: cos(angle * .pi / 180) * radius,
                   y: sin(angle * .pi / 180) * radius)
    }
}

extension View {
    func clockAnimation(angle: Double, radius: Double = 0) -> some View {
        modifier(ClockAnimatableModifier(angle: angle, radius: radius))
    }
}