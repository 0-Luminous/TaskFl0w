import SwiftUI

struct StatisticsView: View {
    @ObservedObject var viewModel: ClockViewModel
    @Environment(\.dismiss) private var dismiss
    
    private var totalTasks: Int {
        viewModel.tasks.count
    }
    
    /// Пример — суммарная продолжительность всех задач, в часах
    private var totalDuration: TimeInterval {
        viewModel.tasks.reduce(0) { $0 + $1.duration }
    }
    
    private var totalDurationHours: Double {
        totalDuration / 3600
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Всего задач: **\(totalTasks)**")
                    .font(.title2)
                
                Text("Суммарная продолжительность:\n**\(String(format: "%.1f", totalDurationHours))** ч")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                
                // Можно добавить графики, диаграммы и т.д.
                
                Spacer()
            }
            .padding()
            .navigationTitle("Статистика")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
}
