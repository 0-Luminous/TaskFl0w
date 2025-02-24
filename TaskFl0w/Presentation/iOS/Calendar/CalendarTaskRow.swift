//
//  CalendarTaskRow.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct CalendarTaskRow: View {
    let task: Task
    let isSelected: Bool
    
    // Пример форматтера времени
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        HStack {
            Circle()
                .fill(task.category.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                
                HStack {
                    Text(timeFormatter.string(from: task.startTime))
                    Text("-")
                    Text(timeFormatter.string(from: task.endTime))
                    Text("•")
                    Text(task.category.rawValue)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: task.category.iconName)
                .foregroundColor(task.category.color)
        }
        .padding(.vertical, 4)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}
