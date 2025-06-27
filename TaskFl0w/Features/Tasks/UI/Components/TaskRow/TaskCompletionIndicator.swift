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
    
    var body: some View {
        Button(action: onToggle) {
            Image(systemName: completionIconName)
                .foregroundColor(completionIconColor)
                .font(.system(size: 22, weight: .medium))
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
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
            return themeManager.isDarkMode ? .green : .green
        }
        
        return themeManager.isDarkMode ? .white.opacity(0.8) : .black.opacity(0.7)
    }
}

// MARK: - Preview
struct TaskCompletionIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            TaskCompletionIndicator(
                isCompleted: false,
                isSelected: false,
                isSelectionMode: false,
                categoryColor: .blue,
                onToggle: {}
            )
            
            TaskCompletionIndicator(
                isCompleted: true,
                isSelected: false,
                isSelectionMode: false,
                categoryColor: .blue,
                onToggle: {}
            )
            
            TaskCompletionIndicator(
                isCompleted: false,
                isSelected: true,
                isSelectionMode: true,
                categoryColor: .blue,
                onToggle: {}
            )
        }
        .padding()
        // .background(Color.gray.opacity(0.1))
    }
} 