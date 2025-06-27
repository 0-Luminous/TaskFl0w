//
//  TaskPriorityIndicator.swift
//  TaskFl0w
//
//  Created by Refactor on Today
//

import SwiftUI

struct TaskPriorityIndicator: View {
    let priority: TaskPriority
    let isCompleted: Bool
    let isSelectionMode: Bool
    let isInArchiveMode: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<priority.rawValue, id: \.self) { _ in
                Rectangle()
                    .fill(priorityColor)
                    .frame(width: 12, height: 3)
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 3)
        .opacity(priorityOpacity)
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .green
        case .none:
            return .clear
        }
    }
    
    private var priorityOpacity: Double {
        (isCompleted && !isSelectionMode && !isInArchiveMode) || isInArchiveMode ? 0.5 : 1.0
    }
} 