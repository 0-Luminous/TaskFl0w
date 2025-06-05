//
//  CategoryDragPreview.swift
//  TaskFl0w
//
//  Created by Yan on 24/4/25.
//
import SwiftUI

struct CategoryDragPreview: View {
    let task: TaskOnRing
    let style: PreviewStyle
    
    enum PreviewStyle {
        case compact
        case expanded
        case minimal
        
        var size: CGFloat {
            switch self {
            case .compact: return 56
            case .expanded: return 72
            case .minimal: return 40
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .compact: return 12
            case .expanded: return 16
            case .minimal: return 8
            }
        }
        
        var iconScale: CGFloat {
            switch self {
            case .compact: return 0.45
            case .expanded: return 0.5
            case .minimal: return 0.4
            }
        }
    }
    
    @ScaledMetric(relativeTo: .largeTitle) private var baseSize: CGFloat = 1
    @Environment(\.colorScheme) private var colorScheme
    
    init(task: TaskOnRing, style: PreviewStyle = .compact) {
        self.task = task
        self.style = style
    }
    
    private var actualSize: CGFloat {
        style.size * baseSize
    }
    
    private var gradientColors: [Color] {
        let baseColor = task.category.color
        return [
            baseColor,
            baseColor.opacity(0.8),
            baseColor.opacity(0.6)
        ]
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: actualSize, height: actualSize)
            .overlay(
                Image(systemName: task.category.iconName)
                    .foregroundStyle(.white)
                    .font(.system(
                        size: actualSize * style.iconScale, 
                        weight: .semibold
                    ))
                    .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
            )
            .shadow(
                color: task.category.color.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
            .contentShape(.dragPreview, RoundedRectangle(cornerRadius: style.cornerRadius))
            .accessibilityLabel("Задача \(task.category.rawValue)")
            .accessibilityHint("Перетащите для создания новой задачи")
    }
}

// MARK: - Preview Provider
#if DEBUG
struct CategoryDragPreview_Previews: PreviewProvider {
    static var previews: some View {
        let sampleTask = TaskOnRing(
            id: UUID(),
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            color: .blue,
            icon: "book.fill",
            category: TaskCategoryModel(
                id: UUID(),
                rawValue: "Обучение",
                iconName: "book.fill",
                color: .blue
            ),
            isCompleted: false
        )
        
        VStack(spacing: 20) {
            CategoryDragPreview(task: sampleTask, style: .minimal)
            CategoryDragPreview(task: sampleTask, style: .compact)
            CategoryDragPreview(task: sampleTask, style: .expanded)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif

