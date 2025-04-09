import SwiftUI

struct TimeTaskEditorView: View {
    @StateObject private var viewModel = TimeTaskEditorViewModel()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var isInternalUpdate: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack {
            if let task = viewModel.editingTask {
                VStack {
                    Text("Task: \(task.title)")
                    Text("Start Time: \(startTime, formatter: DateFormatter.timeOnly)")
                    Text("End Time: \(endTime, formatter: DateFormatter.timeOnly)")

                    HStack {
                        DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .colorScheme(colorScheme)
                            .scaleEffect(1)
                            .onChange(of: startTime) { oldValue, newValue in
                                guard !isInternalUpdate else { return }
                                viewModel.taskManagement.updateTaskStartTimeKeepingEnd(
                                    task, newStartTime: newValue)
                            }

                        DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .colorScheme(colorScheme)
                            .scaleEffect(1)
                            .onChange(of: endTime) { oldValue, newValue in
                                guard !isInternalUpdate else { return }
                                viewModel.taskManagement.updateTaskDuration(task, newEndTime: newValue)
                            }
                    }
                    .padding()
                }
            }
        }
        .transition(.opacity)
        .onChange(of: viewModel.previewTime) { oldValue, newValue in
            if let previewTime = newValue {
                isInternalUpdate = true
                if viewModel.isDraggingStart {
                    startTime = previewTime
                }
                if viewModel.isDraggingEnd {
                    endTime = previewTime
                }
                isInternalUpdate = false
            }
        }
        .onChange(of: viewModel.editingTask) { oldValue, newTask in
            if let newTask = newTask {
                // Обновляем времена при смене задачи
                isInternalUpdate = true
                startTime = newTask.startTime
                endTime = newTask.startTime.addingTimeInterval(newTask.duration)
                isInternalUpdate = false
            }
        }
    }
}

struct TimeTaskEditorView_Previews: PreviewProvider {
    static var previews: some View {
        TimeTaskEditorView()
    }
} 