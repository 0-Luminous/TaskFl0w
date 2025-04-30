//
//  CategoryTasksView.swift
//  TaskFl0w
//
//  Created by Yan on 30/4/25.
//

import SwiftUI

// // Компонент для отображения задач категории на циферблате
// struct CategoryTasksView: View {
//     let category: TaskCategoryModel
//     let tasks: [TaskOnRing]
    
//     var body: some View {
//         VStack(alignment: .leading, spacing: 10) {
//             // Заголовок категории
//             HStack(spacing: 6) {
//                 Image(systemName: category.iconName)
//                     .foregroundColor(category.color)
//                     .font(.system(size: 16))
                
//                 Text(category.rawValue)
//                     .font(.headline)
//                     .foregroundColor(.white)
                
//                 Spacer()
                
//                 Text("\(tasks.count)")
//                     .font(.caption)
//                     .padding(6)
//                     .background(Circle().fill(category.color.opacity(0.3)))
//                     .foregroundColor(.white)
//             }
//             .padding(.horizontal, 10)
//             .padding(.top, 10)
            
//             // Список задач категории
//             VStack(spacing: 8) {
//                 ForEach(tasks) { task in
//                     TaskRowCalendar(task: task)
//                 }
//             }
//             .padding(.horizontal, 10)
//             .padding(.bottom, 10)
//         }
//         .background(
//             RoundedRectangle(cornerRadius: 12)
//                 .fill(Color.black.opacity(0.2))
//                 .overlay(
//                     RoundedRectangle(cornerRadius: 12)
//                         .strokeBorder(category.color.opacity(0.3), lineWidth: 1)
//                 )
//         )
//     }
// }

// Компонент для отображения строки задачи в календаре
struct TaskRowCalendar: View {
    let task: TaskOnRing
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Время задачи
            Text(formatTime(task.startTime) + " - " + formatTime(task.endTime))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.darkGray).opacity(0.6))
        )
    }
    
    // Форматирование времени для отображения
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Расширение для создания примера TaskCategoryModel
extension TaskCategoryModel {
    static var example: TaskCategoryModel {
        TaskCategoryModel(
            id: UUID(),
            rawValue: "Работа",
            iconName: "briefcase",
            color: .blue
        )
    }
}

// Расширение для создания примера TaskOnRing
extension TaskOnRing {
    static var example: TaskOnRing {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate)!
        
        return TaskOnRing(
            id: UUID(),
            startTime: startDate,
            endTime: endDate,
            color: .blue,
            icon: "circle",
            category: TaskCategoryModel.example,
            isCompleted: false
        )
    }
}

//#Preview {
//    CategoryTasksView(category: TaskCategoryModel.example, tasks: [TaskOnRing.example])
//}
