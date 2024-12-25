import SwiftUI

struct MainTaskArcsView: View {
    let tasks: [Task]
    @ObservedObject var viewModel: ClockViewModel
    
    @Binding var selectedTask: Task?
    @Binding var showingTaskDetail: Bool
    @Binding var isEditingMode: Bool
    @Binding var editingTask: Task?
    @Binding var isDraggingStart: Bool
    @Binding var isDraggingEnd: Bool
    @Binding var previewTime: Date?
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(tasks) { task in
                MainClockTaskArc(
                    task: task,
                    geometry: geometry,
                    viewModel: viewModel,
                    selectedTask: $selectedTask,
                    showingTaskDetail: $showingTaskDetail,
                    isEditingMode: $isEditingMode,
                    editingTask: $editingTask,
                    isDraggingStart: $isDraggingStart,
                    isDraggingEnd: $isDraggingEnd,
                    previewTime: $previewTime
                )
            }
        }
    }
}
