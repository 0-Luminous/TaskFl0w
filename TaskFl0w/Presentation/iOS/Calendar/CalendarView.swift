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
                    // Секция календаря с синим фоном
                    ZStack {
                        // Синий фон
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.blue)
                            .edgesIgnoringSafeArea(.top)
                        
                        VStack(spacing: 10) { 
                            // Календарь
                            DatePicker("", selection: $viewModel.selectedDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(20)
                                .padding(.horizontal)
                                .colorScheme(.dark) // Принудительно тёмная схема для календаря
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
                                .padding(.bottom, 20)
                        }
                        .padding(.top, 120)
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Color(.systemBackground))
            .edgesIgnoringSafeArea(.top)
            .navigationTitle("Календарь")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                            Text("Назад")
                        }
                        .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Здесь можно добавить дополнительные действия перед закрытием
                        dismiss()
                    }) {
                        Text("Готово")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    // Функция для создания строки активности
    private func makeActivityRow(name: String, details: String, time: String) -> some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 8, height: 8)
            
            Text(name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            if !details.isEmpty {
                Text(details)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // Форматирование даты для отображения
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }
}

// Расширение для создания скругления только по определенным углам
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
