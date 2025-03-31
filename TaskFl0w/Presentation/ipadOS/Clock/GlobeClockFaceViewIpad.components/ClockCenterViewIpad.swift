//
//  ClockCenterView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct ClockCenterViewIpad: View {
    let currentDate: Date
    let isDraggingStart: Bool
    let isDraggingEnd: Bool
    let task: TaskOnRing?

    var body: some View {
        VStack {
            if isDraggingStart {
                // Показываем время начала задачи
                Text(timeFormatter.string(from: currentDate))
                    .font(.system(size: 36, weight: .bold))  // Увеличенный размер шрифта для iPad
            } else if isDraggingEnd, task != nil {
                // Показываем время окончания задачи
                Text(timeFormatter.string(from: currentDate))
                    .font(.system(size: 36, weight: .bold))  // Увеличенный размер шрифта для iPad
            }
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.black.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14))  // Увеличенный радиус для iPad
    }

    // Форматирование времени
    var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    func formatDuration(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60

        if hours > 0 {
            return String(format: "%dч %02dмин", hours, minutes)
        } else {
            return String(format: "%d мин", minutes)
        }
    }
}
