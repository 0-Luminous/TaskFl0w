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
    
    var body: some View {
        Button(action: handleTap) {
            Image(systemName: completionIconName)
                .foregroundColor(completionIconColor)
                .font(.system(size: 22, weight: .medium))
                .scaleEffect(iconScale)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 44, height: 44)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: iconScale)
        .onChange(of: isCompleted) { newValue in
            if newValue && !isSelectionMode {
                triggerCelebration()
            }
        }
        // Анимационные эффекты ПОВЕРХ основного компонента
        .overlay(
            BubbleCelebrationOverlay(
                isTriggered: shouldTriggerCelebration,
                categoryColor: categoryColor
            )
            .allowsHitTesting(false) // Пузырики не блокируют нажатия
        )
    }
    
    // MARK: - Private Methods
    
    private func handleTap() {
        onToggle()
        
        // Анимация нажатия
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            iconScale = 1.2
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                iconScale = 1.0
            }
        }
    }
    
    private func triggerCelebration() {
        // Анимация кнопки при завершении
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            iconScale = 1.3
        }
        
        // Запуск анимации пузыриков
        shouldTriggerCelebration = true
        
        // Возврат кнопки к нормальному размеру
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                iconScale = 1.0
            }
        }
        
        // Сброс триггера для следующей анимации
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            shouldTriggerCelebration = false
        }
    }
    
    // MARK: - Private Computed Properties
    
    private var completionIconName: String {
        if isSelectionMode {
            return isSelected ? "checkmark.circle.fill" : (isCompleted ? "checkmark.circle" : "circle")
        } else {
            return isCompleted ? "checkmark.circle.fill" : "circle"
        }
    }
    
    private var completionIconColor: Color {
        if isSelectionMode && isSelected {
            return categoryColor
        }
        
        if isCompleted {
            return themeManager.isDarkMode ? .gray : .gray
        }
        
        return themeManager.isDarkMode ? .white.opacity(0.8) : .black.opacity(0.7)
    }
}

// MARK: - Bubble Celebration Overlay
struct BubbleCelebrationOverlay: View {
    let isTriggered: Bool
    let categoryColor: Color
    
    @State private var bubbles: [BubbleParticle] = []
    @State private var showAnimation = false
    
    var body: some View {
        ZStack {
            ForEach(bubbles) { bubble in
                BubbleView(bubble: bubble)
            }
        }
        .frame(width: 150, height: 150) // Расширенная область для пузыриков
        .onChange(of: isTriggered) { triggered in
            if triggered {
                startCelebration()
            }
        }
    }
    
    private func startCelebration() {
        createBubbles()
        animateBubbles()
        
        // Очистка через 3 секунды
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            bubbles.removeAll()
        }
    }
    
    private func createBubbles() {
        let bubbleColors = [
            categoryColor,
            categoryColor.opacity(0.8),
            categoryColor.opacity(0.6),
            .green,
            .mint,
            .cyan,
            .blue.opacity(0.7),
            .teal,
            .indigo.opacity(0.6)
        ]
        
        let numberOfBubbles = Int.random(in: 22...30)
        
        for i in 0..<numberOfBubbles {
            let bubble = BubbleParticle(
                color: bubbleColors.randomElement() ?? categoryColor,
                size: Double.random(in: 6...18),
                angle: Double.random(in: 0...(2 * .pi)),
                distance: Double.random(in: 40...80),
                delay: Double(i) * 0.03
            )
            bubbles.append(bubble)
        }
    }
    
    private func animateBubbles() {
        for (index, bubble) in bubbles.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + bubble.delay) {
                if index < bubbles.count {
                    // Движение от центра
                    let finalX = cos(bubble.angle) * bubble.distance
                    let finalY = sin(bubble.angle) * bubble.distance - Double.random(in: 15...35)
                    
                    withAnimation(.easeOut(duration: Double.random(in: 2.0...3.0))) {
                        bubbles[index].offsetX = finalX
                        bubbles[index].offsetY = finalY
                        bubbles[index].opacity = 0.0
                        bubbles[index].blur = Double.random(in: 2...6)
                    }
                    
                    // Рост пузырика
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                        bubbles[index].scale = Double.random(in: 1.5...2.8)
                    }
                    
                    // Вращение для динамики
                    withAnimation(.easeInOut(duration: 1.5).delay(0.2)) {
                        bubbles[index].rotation = Double.random(in: -60...60)
                    }
                    
                    // Легкое покачивание
                    withAnimation(
                        .easeInOut(duration: 0.8)
                        .repeatCount(3, autoreverses: true)
                        .delay(0.5)
                    ) {
                        bubbles[index].offsetX += Double.random(in: -8...8)
                    }
                }
            }
        }
    }
}

// MARK: - Bubble Particle Model
struct BubbleParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: Double
    let angle: Double
    let distance: Double
    let delay: Double
    
    var offsetX: Double = 0
    var offsetY: Double = 0
    var opacity: Double = 1.0
    var scale: Double = 0.1
    var blur: Double = 0
    var rotation: Double = 0
}

// MARK: - Bubble View
struct BubbleView: View {
    let bubble: BubbleParticle
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        bubble.color.opacity(0.95),
                        bubble.color.opacity(0.6),
                        bubble.color.opacity(0.3),
                        bubble.color.opacity(0.1),
                        Color.clear
                    ]),
                    center: UnitPoint(x: 0.25, y: 0.25), // 3D эффект
                    startRadius: 1,
                    endRadius: bubble.size / 2
                )
            )
            .frame(width: bubble.size, height: bubble.size)
            .scaleEffect(bubble.scale)
            .opacity(bubble.opacity)
            .blur(radius: bubble.blur)
            .rotationEffect(.degrees(bubble.rotation))
            .offset(x: bubble.offsetX, y: bubble.offsetY)
            .shadow(
                color: bubble.color.opacity(0.5),
                radius: 4,
                x: 2,
                y: 3
            )
    }
}

// MARK: - Preview
struct TaskCompletionIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 50) {
                Text("🎉 Overlay Bubble Animation")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                // Базовые состояния
                HStack(spacing: 60) {
                    VStack {
                        Text("Incomplete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TaskCompletionIndicator(
                            isCompleted: false,
                            isSelected: false,
                            isSelectionMode: false,
                            categoryColor: .blue,
                            onToggle: {}
                        )
                    }
                    
                    VStack {
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TaskCompletionIndicator(
                            isCompleted: true,
                            isSelected: false,
                            isSelectionMode: false,
                            categoryColor: .green,
                            onToggle: {}
                        )
                    }
                    
                    VStack {
                        Text("Selection Mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TaskCompletionIndicator(
                            isCompleted: false,
                            isSelected: true,
                            isSelectionMode: true,
                            categoryColor: .purple,
                            onToggle: {}
                        )
                    }
                }
                
                // Интерактивные демо
                InteractiveBubbleDemo()
                
                // Цветные демо
                ColorBubbleDemo()
            }
            .padding(80) // Больше места для пузыриков
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Interactive Demo
struct InteractiveBubbleDemo: View {
    @State private var isCompleted = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🫧 Interactive Overlay Demo")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap to see bubbles fly OVER the indicator!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            TaskCompletionIndicator(
                isCompleted: isCompleted,
                isSelected: false,
                isSelectionMode: false,
                categoryColor: .mint,
                onToggle: {
                    isCompleted.toggle()
                }
            )
            
            Button("Reset") {
                isCompleted = false
            }
            .font(.caption)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Color Demo
struct ColorBubbleDemo: View {
    @State private var selectedIndex = 0
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    let colorNames = ["Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Pink"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🎨 Color Variety Demo")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Different categories = Different bubble colors!")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 30) {
                ForEach(0..<colors.count, id: \.self) { index in
                    VStack {
                        Text(colorNames[index])
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        TaskCompletionIndicator(
                            isCompleted: false,
                            isSelected: false,
                            isSelectionMode: false,
                            categoryColor: colors[index],
                            onToggle: {}
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
} 