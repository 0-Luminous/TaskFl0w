//
//  TaskRow.swift
//  ToDoList
//
//  Created by Yan on 23/3/25.
//
import SwiftUI
import UIKit

struct TaskRow: View {
    let item: ToDoItem
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onShare: () -> Void
    let categoryColor: Color

    @State private var isLongPressed: Bool = false

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button(action: onToggle) {
                        Image(systemName: item.isCompleted ? "checkmark.circle" : "circle")
                            .foregroundColor(item.isCompleted ? .yellow : categoryColor)
                            .font(.system(size: 22))
                    }

                    Text(item.title)
                        .strikethrough(item.isCompleted)
                        .foregroundColor(item.isCompleted ? .gray : .white)

                    Spacer()
                }

                Text(item.content)
                    .font(.subheadline)
                    .foregroundColor(item.isCompleted ? .gray : .white)
                    .lineLimit(2)
                    .padding(.leading, 30)

                Text(item.date.formattedForTodoList())
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.leading, 30)
            }
            .padding(10)
            .background(
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.systemBackground).opacity(0.15))
                    
                    // Боковая полоса с цветом категории
                    Rectangle()
                        .fill(categoryColor)
                        .frame(width: 5)
                }
            )
            .contentShape(Rectangle())
        }
    }
}
