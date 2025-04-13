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

    @State private var isLongPressed: Bool = false

    var taskBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .foregroundColor(.white)

            Text(item.content)
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(2)

            Text(item.date.formattedForTodoList())
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(width: 320)
        .padding(.vertical, 12)
        .cornerRadius(12)
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button(action: onToggle) {
                        Image(systemName: item.isCompleted ? "checkmark.circle" : "circle")
                            .foregroundColor(item.isCompleted ? .yellow : .gray)
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
            .contentShape(Rectangle())
            .contextMenu {
                Button(action: onEdit) {
                    Label("Редактировать", systemImage: "pencil")
                }

                Button(action: onShare) {
                    Label("Поделиться", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive, action: onDelete) {
                    Label("Удалить", systemImage: "trash")
                }
            } preview: {
                taskBody
                    .onAppear {
                        isLongPressed = true
                    }
            }
            .onDisappear {
                isLongPressed = false
            }
        }
    }
    var shouldHideDivider: Bool {
        return isLongPressed
    }
}
