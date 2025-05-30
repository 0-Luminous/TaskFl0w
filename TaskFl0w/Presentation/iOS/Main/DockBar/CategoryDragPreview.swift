//
//  CategoryDragPreview.swift
//  TaskFl0w
//
//  Created by Yan on 24/4/25.
//
import SwiftUI

struct CategoryDragPreview: View {
        let task: TaskOnRing

        @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 56
        private let cornerRadius: CGFloat = 12
        
        var body: some View {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            task.category.color,
                            task.category.color.opacity(0.7),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: task.category.iconName)
                        .foregroundStyle(.white)
                        .font(.system(size: size * 0.45, weight: .semibold))
                )
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                .contentShape(.dragPreview, RoundedRectangle(cornerRadius: cornerRadius))
                .accessibilityLabel("Task")
        }
    }

