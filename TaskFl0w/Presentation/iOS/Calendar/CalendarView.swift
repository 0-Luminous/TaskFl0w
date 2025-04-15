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
    @State private var temporaryDate: Date // Временная дата для хранения выбора
    @State private var selectedMode: BottomBarCalendar.ViewMode = .week
    
    init(viewModel: ClockViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        // Инициализируем временную дату текущей выбранной датой
        _temporaryDate = State(initialValue: viewModel.selectedDate)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
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
                                DatePicker("", selection: $temporaryDate, displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .padding()
                                    .background(Color.black.opacity(0.5))
                                    .cornerRadius(20)
                                    .padding(.horizontal)
                                    .colorScheme(.dark) // Принудительно тёмная схема для календаря
                                    .padding(.bottom, 20)
                            }
                            .padding(.top, 120)
                        }
                    }
                    .padding(.bottom, 100) // Увеличиваем отступ для BottomBar
                }
                .background(Color(red: 0.098, green: 0.098, blue: 0.098))
                .edgesIgnoringSafeArea(.top)
                
                VStack {
                    Spacer()
                    BottomBarCalendar(selectedMode: $selectedMode) {
                        // Действие при нажатии на кнопку добавления
                        print("Добавление новой задачи")
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
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
                        // Применяем выбранную дату и выполняем все необходимые обновления
                        viewModel.selectedDate = temporaryDate
                        
                        // Обновляем UI циферблата
                        viewModel.objectWillChange.send()
                        
                        // Фильтруем задачи на выбранную дату
                        viewModel.tasks = viewModel.sharedState.tasks.filter { task in
                            Calendar.current.isDate(task.startTime, inSameDayAs: temporaryDate)
                        }
                        
                        // Обновляем также состояние clockState
                        viewModel.clockState.selectedDate = temporaryDate
                        viewModel.updateMarkersViewModel()
                        
                        // Закрываем календарь
                        dismiss()
                    }) {
                        Text("Готово")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onChange(of: selectedMode) { newMode in
            // Здесь можно добавить логику при изменении режима отображения
            print("Выбран режим: \(newMode.rawValue)")
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
