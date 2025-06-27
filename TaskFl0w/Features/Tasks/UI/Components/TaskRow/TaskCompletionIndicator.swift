//
//  TaskCompletionIndicator.swift
//  TaskFl0w
//
//  Created by Refactor on Today
//

import SwiftUI

struct TaskCompletionIndicator: View {
    let isCompleted: Bool
    let isSelected: Bool
    let isSelectionMode: Bool
    let categoryColor: Color
    let onToggle: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var shouldTriggerCelebration = false
    @State private var iconScale: CGFloat = 1.0
    @State private var pulseEffect: Bool = false
    @State private var tapFeedback: Bool = false
    
    var body: some View {
        Button(action: handleTap) {
            ZStack {
                // Pulse background для завершенных задач
                if isCompleted && !isSelectionMode {
                    Circle()
                        .fill(completionIconColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                        .scaleEffect(pulseEffect ? 1.3 : 1.0)
                        .opacity(pulseEffect ? 0.0 : 1.0)
                        .animation(
                            .easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false),
                            value: pulseEffect
                        )
                }
                
                // Основная иконка с улучшенным дизайном
                Image(systemName: completionIconName)
                    .foregroundStyle(
                        iconGradient
                    )
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .scaleEffect(iconScale)
                    .rotationEffect(.degrees(tapFeedback ? 360 : 0))
                    .shadow(
                        color: completionIconColor.opacity(0.3),
                        radius: isCompleted ? 8 : 2,
                        x: 0,
                        y: isCompleted ? 4 : 1
                    )
            }
        }
        .buttonStyle(EnhancedButtonStyle())
        .frame(width: 50, height: 50)
        .background(
            Circle()
                .fill(backgroundGradient)
                .overlay(
                    Circle()
                        .stroke(borderGradient, lineWidth: 2)
                )
        )
        .onChange(of: isCompleted) { newValue in
            if newValue && !isSelectionMode {
                triggerCelebration()
                startPulseEffect()
            }
        }
        // Premium анимационные эффекты ПОВЕРХ
        .overlay(
            PremiumBubbleCelebrationOverlay(
                isTriggered: shouldTriggerCelebration,
                categoryColor: categoryColor,
                isCompleted: isCompleted
            )
            .allowsHitTesting(false)
        )
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
    
    // MARK: - Private Methods
    
    private func handleTap() {
        // Haptic feedback для премиум ощущений
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        onToggle()
        
        // Микроанимация нажатия с вращением
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            iconScale = 1.1
            tapFeedback = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                iconScale = 1.0
                tapFeedback = false
            }
        }
    }
    
    private func triggerCelebration() {
        // Более драматичная анимация для завершения
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
            iconScale = 1.4
        }
        
        // Haptic celebration
        let celebrationFeedback = UINotificationFeedbackGenerator()
        celebrationFeedback.notificationOccurred(.success)
        
        shouldTriggerCelebration = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                iconScale = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            shouldTriggerCelebration = false
        }
    }
    
    private func startPulseEffect() {
        pulseEffect = true
    }
    
    // MARK: - Computed Properties
    
    private var completionIconName: String {
        if isSelectionMode {
            return isSelected ? "checkmark.circle.fill" : (isCompleted ? "checkmark.circle" : "circle")
        } else {
            return isCompleted ? "checkmark.circle.fill" : "circle"
        }
    }
    
    private var iconGradient: some ShapeStyle {
        if isSelectionMode && isSelected {
            return LinearGradient(
                colors: [categoryColor, categoryColor.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).opacity(1.0)
        }
        
        if isCompleted {
            return LinearGradient(
                colors: [.gray, Color.gray.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).opacity(1.0)
        }
        
        return LinearGradient(
            colors: [
                themeManager.isDarkMode ? .white.opacity(0.9) : .black.opacity(0.8),
                themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ).opacity(1.0)
    }
    
    private var completionIconColor: Color {
        if isSelectionMode && isSelected {
            return categoryColor
        }
        if isCompleted {
            return .green
        }
        return themeManager.isDarkMode ? .white.opacity(0.8) : .black.opacity(0.7)
    }
    
    private var backgroundGradient: some ShapeStyle {
        if isCompleted {
            return LinearGradient(
                colors: [
                    Color.green.opacity(0.1),
                    Color.green.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        return LinearGradient(
            colors: [
                themeManager.isDarkMode ? Color.black.opacity(0.3) : Color.white.opacity(0.8),
                themeManager.isDarkMode ? Color.black.opacity(0.1) : Color.white.opacity(0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var borderGradient: some ShapeStyle {
        if isCompleted {
            return LinearGradient(
                colors: [Color.green.opacity(0.6), Color.green.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        return LinearGradient(
            colors: [
                categoryColor.opacity(0.4),
                categoryColor.opacity(0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var accessibilityLabel: String {
        if isCompleted {
            return "Completed task"
        } else if isSelectionMode {
            return isSelected ? "Selected task" : "Unselected task"
        } else {
            return "Incomplete task"
        }
    }
    
    private var accessibilityHint: String {
        if isSelectionMode {
            return "Double tap to toggle selection"
        } else {
            return "Double tap to mark as completed"
        }
    }
}

// MARK: - Enhanced Button Style
struct EnhancedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Data Models (ИСПРАВЛЕНО: добавлены недостающие типы)
struct PremiumBubbleParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: Double
    let angle: Double
    let distance: Double
    let delay: Double
    let physics: BubblePhysics
    
    var offsetX: Double = 0
    var offsetY: Double = 0
    var opacity: Double = 1.0
    var scale: Double = 0.1
    var blur: Double = 0
    var rotation: Double = 0
}

struct BubblePhysics {
    let gravity: Double
    let airResistance: Double
    let bounciness: Double
}

struct RingParticle: Identifiable {
    let id = UUID()
    var size: CGFloat
    var scale: CGFloat
    var opacity: Double
    var lineWidth: CGFloat
    let delay: Double
}

struct SparkleParticle: Identifiable {
    let id = UUID()
    let size: Double
    let angle: Double
    let distance: Double
    let delay: Double
    let twinkleSpeed: Double
    
    var offsetX: Double = 0
    var offsetY: Double = 0
    var opacity: Double = 1.0
    var twinkle: Double = 0.5
}

// MARK: - Premium Bubble Celebration Overlay
struct PremiumBubbleCelebrationOverlay: View {
    let isTriggered: Bool
    let categoryColor: Color
    let isCompleted: Bool
    
    @State private var bubbles: [PremiumBubbleParticle] = []
    @State private var sparkles: [SparkleParticle] = []
    @State private var rings: [RingParticle] = []
    
    var body: some View {
        ZStack {
            // Expanding rings для драматичности
            ForEach(rings) { ring in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                categoryColor.opacity(ring.opacity),
                                categoryColor.opacity(ring.opacity * 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: ring.lineWidth
                    )
                    .frame(width: ring.size, height: ring.size)
                    .opacity(ring.opacity)
                    .scaleEffect(ring.scale)
            }
            
            // Premium bubbles с улучшенной физикой
            ForEach(bubbles) { bubble in
                PremiumBubbleView(bubble: bubble)
            }
            
            // Sparkles для магического эффекта
            ForEach(sparkles) { sparkle in
                SparkleView(sparkle: sparkle)
            }
        }
        .frame(width: 180, height: 180)
        .onChange(of: isTriggered) { triggered in
            if triggered {
                startPremiumCelebration()
            }
        }
    }
    
    private func startPremiumCelebration() {
        createRings()
        createPremiumBubbles()
        createSparkles()
        animateAllEffects()
        
        // Cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            rings.removeAll()
            bubbles.removeAll()
            sparkles.removeAll()
        }
    }
    
    private func createRings() {
        for i in 0..<3 {
            let ring = RingParticle(
                size: 50,
                scale: 1.0,
                opacity: 0.8,
                lineWidth: 3 - CGFloat(i),
                delay: Double(i) * 0.2
            )
            rings.append(ring)
        }
    }
    
    private func createPremiumBubbles() {
        let premiumColors = createPremiumColorPalette()
        let numberOfBubbles = Int.random(in: 25...35)
        
        for i in 0..<numberOfBubbles {
            let bubble = PremiumBubbleParticle(
                color: premiumColors.randomElement() ?? categoryColor,
                size: Double.random(in: 4...20),
                angle: Double.random(in: 0...(2 * .pi)),
                distance: Double.random(in: 50...100),
                delay: Double(i) * 0.025,
                physics: BubblePhysics(
                    gravity: Double.random(in: 0.1...0.3),
                    airResistance: Double.random(in: 0.02...0.05),
                    bounciness: Double.random(in: 0.3...0.7)
                )
            )
            bubbles.append(bubble)
        }
    }
    
    private func createSparkles() {
        for i in 0..<15 {
            let sparkle = SparkleParticle(
                size: Double.random(in: 2...6),
                angle: Double.random(in: 0...(2 * .pi)),
                distance: Double.random(in: 30...70),
                delay: Double(i) * 0.1,
                twinkleSpeed: Double.random(in: 0.5...1.5)
            )
            sparkles.append(sparkle)
        }
    }
    
    private func createPremiumColorPalette() -> [Color] {
        [
            categoryColor,
            categoryColor.opacity(0.9),
            categoryColor.opacity(0.7),
            categoryColor.opacity(0.5),
            .green,
            .mint,
            .cyan.opacity(0.8),
            .blue.opacity(0.7),
            .teal.opacity(0.8),
            .indigo.opacity(0.6),
            Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.7), // Golden
            Color(red: 1.0, green: 0.6, blue: 0.8).opacity(0.6)  // Rose gold
        ]
    }
    
    private func animateAllEffects() {
        animateRings()
        animatePremiumBubbles()
        animateSparkles()
    }
    
    private func animateRings() {
        for (index, _) in rings.enumerated() {
            let delay = rings[index].delay
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if index < rings.count {
                    withAnimation(.easeOut(duration: 1.5)) {
                        rings[index].scale = 3.0
                        rings[index].opacity = 0.0
                        rings[index].lineWidth = 0.5
                    }
                }
            }
        }
    }
    
    private func animatePremiumBubbles() {
        for (index, bubble) in bubbles.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + bubble.delay) {
                if index < bubbles.count {
                    let finalX = cos(bubble.angle) * bubble.distance
                    let finalY = sin(bubble.angle) * bubble.distance - 20 + bubble.physics.gravity * 100
                    
                    withAnimation(.easeOut(duration: Double.random(in: 2.5...3.5))) {
                        bubbles[index].offsetX = finalX
                        bubbles[index].offsetY = finalY
                        bubbles[index].opacity = 0.0
                        bubbles[index].blur = Double.random(in: 3...7)
                    }
                    
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
                        bubbles[index].scale = Double.random(in: 1.8...3.2)
                    }
                    
                    withAnimation(.easeInOut(duration: 2.0).delay(0.3)) {
                        bubbles[index].rotation = Double.random(in: -90...90)
                    }
                    
                    // Floating motion
                    withAnimation(
                        .easeInOut(duration: 1.2)
                        .repeatCount(3, autoreverses: true)
                        .delay(0.8)
                    ) {
                        bubbles[index].offsetY -= 15
                        bubbles[index].offsetX += Double.random(in: -10...10)
                    }
                }
            }
        }
    }
    
    private func animateSparkles() {
        for (index, sparkle) in sparkles.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + sparkle.delay) {
                if index < sparkles.count {
                    let finalX = cos(sparkle.angle) * sparkle.distance
                    let finalY = sin(sparkle.angle) * sparkle.distance - 30
                    
                    withAnimation(.easeOut(duration: 2.0)) {
                        sparkles[index].offsetX = finalX
                        sparkles[index].offsetY = finalY
                        sparkles[index].opacity = 0.0
                    }
                    
                    // Twinkling effect
                    withAnimation(
                        .easeInOut(duration: sparkle.twinkleSpeed)
                        .repeatForever(autoreverses: true)
                    ) {
                        sparkles[index].twinkle = 1.0
                    }
                }
            }
        }
    }
}

// MARK: - Views
struct PremiumBubbleView: View {
    let bubble: PremiumBubbleParticle
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        bubble.color.opacity(1.0),
                        bubble.color.opacity(0.8),
                        bubble.color.opacity(0.4),
                        bubble.color.opacity(0.1),
                        Color.clear
                    ]),
                    center: UnitPoint(x: 0.2, y: 0.2),
                    startRadius: 1,
                    endRadius: bubble.size / 2
                )
            )
            .overlay(
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.8),
                                Color.clear
                            ]),
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: 1,
                            endRadius: bubble.size / 4
                        )
                    )
            )
            .frame(width: bubble.size, height: bubble.size)
            .scaleEffect(bubble.scale)
            .opacity(bubble.opacity)
            .blur(radius: bubble.blur)
            .rotationEffect(.degrees(bubble.rotation))
            .offset(x: bubble.offsetX, y: bubble.offsetY)
            .shadow(
                color: bubble.color.opacity(0.6),
                radius: 6,
                x: 3,
                y: 4
            )
    }
}

struct SparkleView: View {
    let sparkle: SparkleParticle
    
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: sparkle.size, weight: .medium))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color.yellow.opacity(0.9),
                        Color.orange.opacity(0.7),
                        Color.pink.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .scaleEffect(0.5 + sparkle.twinkle * 0.5)
            .opacity(sparkle.opacity)
            .offset(x: sparkle.offsetX, y: sparkle.offsetY)
            .shadow(color: .yellow.opacity(0.5), radius: 3, x: 0, y: 0)
    }
}

// MARK: - Preview
struct TaskCompletionIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 60) {
                Text("🎨 Premium Bubble Animation")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                // Premium demo grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 80) {
                    ForEach(PreviewDemo.allCases, id: \.self) { demo in
                        VStack(spacing: 15) {
                            Text(demo.title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            TaskCompletionIndicator(
                                isCompleted: demo.isCompleted,
                                isSelected: demo.isSelected,
                                isSelectionMode: demo.isSelectionMode,
                                categoryColor: demo.color,
                                onToggle: {}
                            )
                        }
                    }
                }
                
                PremiumInteractiveDemo()
            }
            .padding(100)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(.systemGroupedBackground),
                    Color(.systemGroupedBackground).opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

enum PreviewDemo: CaseIterable {
    case incomplete, completed, selected, premium1, premium2, premium3
    
    var title: String {
        switch self {
        case .incomplete: return "Incomplete\nTask"
        case .completed: return "Completed\nTask"
        case .selected: return "Selection\nMode"
        case .premium1: return "Work\nCategory"
        case .premium2: return "Personal\nCategory"
        case .premium3: return "Health\nCategory"
        }
    }
    
    var isCompleted: Bool {
        switch self {
        case .completed, .premium1, .premium2: return true
        default: return false
        }
    }
    
    var isSelected: Bool {
        switch self {
        case .selected: return true
        default: return false
        }
    }
    
    var isSelectionMode: Bool {
        switch self {
        case .selected: return true
        default: return false
        }
    }
    
    var color: Color {
        switch self {
        case .incomplete, .completed: return .blue
        case .selected: return .purple
        case .premium1: return .orange
        case .premium2: return .pink
        case .premium3: return .mint
        }
    }
}

struct PremiumInteractiveDemo: View {
    @State private var isCompleted = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("🫧 Premium Interactive Demo")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Tap to experience premium celebration animation with haptic feedback!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TaskCompletionIndicator(
                isCompleted: isCompleted,
                isSelected: false,
                isSelectionMode: false,
                categoryColor: .indigo,
                onToggle: {
                    isCompleted.toggle()
                }
            )
            
            Button("Reset Animation") {
                isCompleted = false
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
} 