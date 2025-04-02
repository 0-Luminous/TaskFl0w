//
//  CalendarView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel: ClockViewModel
    @State private var selectedTask: TaskOnRing?
    @State private var isEditingTask = false
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ClockViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Вычислимые свойства
    var filteredTasks: [Date: [TaskOnRing]] {
        let allTasks =
            searchText.isEmpty
            ? viewModel.tasks
            : viewModel.tasks.filter { $0.title.lowercased().contains(searchText.lowercased()) }
        return Dictionary(grouping: allTasks) { task in
            Calendar.current.startOfDay(for: task.startTime)
        }
    }

    var sortedDates: [Date] {
        filteredTasks.keys.sorted()
    }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM"
        f.locale = Locale(identifier: "ru_RU")
        return f
    }()

    var body: some View {
        NavigationView {
            VStack {
                DatePicker("", selection: $viewModel.selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .onChange(of: viewModel.selectedDate) { oldValue, newValue in
                        dismiss()
                    }

                // Разбиваем логику списка:
                let dates = sortedDates

                List {
                    ForEach(dates, id: \.self) { date in
                        if Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate) {
                            let tasksForDate =
                                filteredTasks[date]?.sorted { $0.startTime < $1.startTime } ?? []

                            Section(header: Text(dateFormatter.string(from: date))) {
                                ForEach(tasksForDate) { task in
                                    CalendarTaskRow(task: task, isSelected: selectedTask == task)
                                        .onTapGesture {
                                            selectedTask = task
                                            isEditingTask = true
                                        }
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                selectedTask = task
                                                isEditingTask = true
                                            } label: {
                                                Label("Редактировать", systemImage: "pencil")
                                            }
                                            .tint(.blue)
                                        }
                                }
                                .onDelete { indexSet in
                                    deleteTask(at: indexSet, for: date)
                                }
                            }
                            // Если всё равно громоздко, можно закомментировать:
                            // .transition(.asymmetric(insertion: .move(edge: .trailing),
                            //                         removal: .move(edge: .leading)))
                        }
                    }
                }
                // Тоже можно временно закомментировать:
                // .animation(.default, value: viewModel.selectedDate)
            }
            .searchable(text: $searchText)
            .navigationTitle("Календарь")
        }
    }

    // MARK: - Удаление задачи
    private func deleteTask(at offsets: IndexSet, for date: Date) {
        guard let tasksForDate = filteredTasks[date] else { return }
        for index in offsets {
            let task = tasksForDate[index]
            viewModel.taskManagement.removeTask(task)
        }
    }
}
