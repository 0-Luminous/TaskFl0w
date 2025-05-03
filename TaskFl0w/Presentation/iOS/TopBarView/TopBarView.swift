//
//  TopBarView.swift
//  TaskFl0w
//
//  Created by Yan on 4/5/25.
//

import SwiftUI

struct TopBarView: View {
    let viewModel: ClockViewModel
    let showSettingsAction: () -> Void
    let toggleCalendarAction: () -> Void
    let isCalendarVisible: Bool
    
    var body: some View {
        HStack {
            if !isCalendarVisible {
                Button(action: showSettingsAction) {
                    Image(systemName: "gear")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                        .padding(.leading, 16)
                }
                .padding(.top, 5)
            } else {
                // Пустой элемент для сохранения структуры при скрытой кнопке
                Color.clear
                    .frame(width: 20)
                    .padding(.leading, 16)
            }
            
            Spacer()
            
            // Здесь отображаем либо кнопку с датой, либо мини-календарь
            if !isCalendarVisible {
                // Кнопка с датой и днем недели
                Button(action: toggleCalendarAction) {
                    VStack(spacing: 0) { // Уменьшаем отступ между элементами
                        Text(viewModel.formattedDate)
                            .font(.subheadline) // Уменьшаем размер шрифта
                            .foregroundColor(.primary)
                        Text(viewModel.formattedWeekday)
                            .font(.caption) // Уменьшаем размер шрифта
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 3) // Уменьшаем вертикальный отступ
                    .padding(.horizontal, 15) // Уменьшаем горизонтальный отступ
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                    )
                }
                .padding(.top, 5)
            } else {
                // Мини-версия WeekCalendarView прямо в TopBar
                WeekCalendarView(selectedDate: .constant(viewModel.selectedDate))
                    .scaleEffect(0.5)
                    .frame(height: 35)
            }
            
            Spacer()
            
            // Пустой элемент для баланса с кнопкой настроек
            Color.clear
                .frame(width: 20)
                .padding(.trailing, 16)
        }
        .padding(.top, 5)
        .padding(.bottom, 2)
        .frame(height: 24) // Явно задаем высоту панели, как в стандартном навбаре
        // .background(
        //     Rectangle()
        //         .fill(Color(red: 0.098, green: 0.098, blue: 0.098))
        //         .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
        // )
    }
}

