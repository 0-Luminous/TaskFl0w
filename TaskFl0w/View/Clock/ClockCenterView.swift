import SwiftUI

struct ClockCenterView: View {
    let currentDate: Date
    let isDraggingStart: Bool
    let isDraggingEnd: Bool
    let task: Task?
    
    var body: some View {
        VStack {
            if isDraggingStart {
                // Показываем только время начала
                Text(timeFormatter.string(from: currentDate))
                    .font(.system(size: 24, weight: .bold))
            } else if isDraggingEnd, let task = task {
                // Показываем продолжительность
                let duration = currentDate.timeIntervalSince(task.startTime)
                Text(formatDuration(duration))
                    .font(.system(size: 24, weight: .bold))
            }
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.black.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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