//
//  TaskContentView.swift
//  TaskFl0w
//
//  Created by Refactor on Today
//

import SwiftUI

struct TaskContentView: View {
    let item: ToDoItem
    let isSelectionMode: Bool
    let isInArchiveMode: Bool
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .strikethrough(shouldStrikethrough)
                .foregroundColor(titleColor)
                .fontWeight(getFontWeight(for: item.priority))
                .animation(.easeInOut(duration: 0.2), value: item.isCompleted)
            
            if let deadline = item.deadline {
                DeadlineView(
                    deadline: deadline,
                    isCompleted: item.isCompleted,
                    isSelectionMode: isSelectionMode,
                    isInArchiveMode: isInArchiveMode
                )
            }
        }
    }
    
    private var shouldStrikethrough: Bool {
        item.isCompleted && !isSelectionMode && !isInArchiveMode
    }
    
    private var titleColor: Color {
        let isCompletedAndNotInteractive = item.isCompleted && !isSelectionMode && !isInArchiveMode
        
        if themeManager.isDarkMode {
            return isCompletedAndNotInteractive ? .gray : .white
        } else {
            return isCompletedAndNotInteractive ? .gray : .black
        }
    }
    
    private func getFontWeight(for priority: TaskPriority) -> Font.Weight {
        return .regular
    }
}

struct DeadlineView: View {
    let deadline: Date
    let isCompleted: Bool
    let isSelectionMode: Bool
    let isInArchiveMode: Bool
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flag.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(deadlineColor)
            
            Text(formatDeadline(deadline))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(deadlineColor)
        }
        .opacity(deadlineOpacity)
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
    }
    
    private var deadlineOpacity: Double {
        (isCompleted && !isSelectionMode && !isInArchiveMode) || isInArchiveMode ? 0.5 : 1.0
    }
    
    private var deadlineColor: Color {
        let now = Date()
        let timeInterval = deadline.timeIntervalSince(now)
        
        if timeInterval < 0 {
            return .red
        }
        
        if timeInterval < 3600 {
            return .red
        }
        
        if timeInterval < 21600 {
            return .orange
        }
        
        if timeInterval < 86400 {
            return .yellow
        }
        
        return themeManager.isDarkMode ? .white.opacity(0.7) : .secondary
    }
    
    private func formatDeadline(_ deadline: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        let timeComponents = calendar.dateComponents([.hour, .minute], from: deadline)
        let hasSpecificTime = timeComponents.hour != 0 || timeComponents.minute != 0

        if calendar.isDateInToday(deadline) {
            if hasSpecificTime {
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                return "сегодня \(timeFormatter.string(from: deadline))"
            } else {
                return "сегодня"
            }
        }
        
        if calendar.isDateInTomorrow(deadline) {
            if hasSpecificTime {
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                return "завтра \(timeFormatter.string(from: deadline))"
            } else {
                return "завтра"
            }
        }
        
        let weekOfYear = calendar.component(.weekOfYear, from: now)
        let deadlineWeek = calendar.component(.weekOfYear, from: deadline)
        let year = calendar.component(.year, from: now)
        let deadlineYear = calendar.component(.year, from: deadline)
        
        if weekOfYear == deadlineWeek && year == deadlineYear {
            let weekdayFormatter = DateFormatter()
            weekdayFormatter.dateFormat = "EEEE"
            
            if hasSpecificTime {
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                return "\(weekdayFormatter.string(from: deadline)) \(timeFormatter.string(from: deadline))"
            } else {
                return weekdayFormatter.string(from: deadline)
            }
        }
        
        if hasSpecificTime {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: deadline)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            return dateFormatter.string(from: deadline)
        }
    }
} 