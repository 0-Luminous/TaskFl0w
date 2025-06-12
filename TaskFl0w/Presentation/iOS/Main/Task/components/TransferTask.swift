//
//  TransferTask.swift
//  TaskFl0w
//
//  Created by Yan on 12/6/25.
//
import SwiftUI

struct TransferTaskView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    let selectedTasksCount: Int
    let onMoveTasksToDate: (Date) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Функция для генерации виброотдачи
    private func generateHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Выберите дату для переноса задач")
                    .font(.headline)
                    .padding(.top)
                
                MonthCalendarView(
                    selectedDate: $selectedDate,
                    onHideCalendar: {
                        isPresented = false
                    },
                    isSwipeToHideEnabled: false
                )
                .frame(maxWidth: .infinity)
                
                HStack(spacing: 20) {
                    Button("Отмена") {
                        isPresented = false
                    }
                    .foregroundColor(.red)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 0.9, green: 0.9, blue: 0.9))
                    )
                    
                    Button("Перенести") {
                        generateHapticFeedback()
                        onMoveTasksToDate(selectedDate)
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 0.9, green: 0.9, blue: 0.9))
                    )
                    .disabled(selectedTasksCount == 0)
                    .opacity(selectedTasksCount == 0 ? 0.5 : 1.0)
                }
                .padding()
                
                Spacer()
            }
            .background(themeManager.isDarkMode ? Color(red: 0.098, green: 0.098, blue: 0.098) : Color(red: 0.95, green: 0.95, blue: 0.95))
            .navigationBarHidden(true)
        }
        .presentationDetents([.large])
    }
}

#Preview {
    TransferTaskView(
        selectedDate: .constant(Date()),
        isPresented: .constant(true),
        selectedTasksCount: 3,
        onMoveTasksToDate: { _ in }
    )
}