//
//  CalendarView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel: ClockViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ClockViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Календарь
                    DatePicker("", selection: $viewModel.selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                        .onChange(of: viewModel.selectedDate) { oldValue, newValue in
                            // Обновляем UI циферблата
                            viewModel.objectWillChange.send()
                            // Фильтруем задачи на выбранную дату
                            viewModel.tasks = viewModel.sharedState.tasks.filter { task in
                                Calendar.current.isDate(task.startTime, inSameDayAs: newValue)
                            }
                            // Обновляем также состояние clockState
                            viewModel.clockState.selectedDate = newValue
                            viewModel.updateMarkersViewModel()
                            dismiss()
                        }
                    
                    // Здесь можно добавить дополнительный контент календаря
                    // например, список задач на выбранную дату
                    VStack(alignment: .leading) {
                        Text("Выбранная дата:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Text("\(viewModel.selectedDate, formatter: dateFormatter)")
                            .padding(.horizontal)
                            .foregroundColor(.secondary)
                        
                        Divider()
                            .padding(.vertical, 10)
                        
                        // Заглушка для списка задач
                        Text("Нет запланированных задач на этот день")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Календарь")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Закрыть")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    // Форматирование даты для отображения
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }
}
