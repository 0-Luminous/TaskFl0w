//
//  CategoryDragPreview.swift
//  TaskFl0w
//
//  Created by Yan on 24/4/25.
//
import SwiftUI

struct CategoryDragPreview: View {
        let task: TaskOnRing  // Заменяем Task на TaskOnRing
        
        // Гибкие константы
        @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 56
        private let cornerRadius: CGFloat = 12
        
        var body: some View {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                // 1️⃣ Градиент, чтобы выглядело «живее»
                .fill(
                    LinearGradient(
                        colors: [
                            task.category.color,  // основной
                            task.category.color.opacity(0.7),  // затемнённый
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                // 2️⃣ Контрастная иконка
                .overlay(
                    Image(systemName: task.category.iconName)
//                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white)
                        .font(.system(size: size * 0.45, weight: .semibold))
                )
                // 3️⃣ Тень для глубины
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                // 4️⃣ Чёткая hit-area для drag'а
                .contentShape(.dragPreview, RoundedRectangle(cornerRadius: cornerRadius))
                // 5️⃣ VoiceOver
                .accessibilityLabel("Task") // Также здесь была ссылка на task.title, которого нет в TaskOnRing
        }
    }

