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
    let searchAction: () -> Void
    
    var body: some View {
        HStack {
            // Кнопка поиска слева
            Button(action: searchAction) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
                    .padding(.leading, 16)
            }
            .padding(.bottom, 4)
                
            Spacer()
            
            // Здесь отображаем либо кнопку с датой, либо мини-календарь
            if !isCalendarVisible {
                // Кнопка с датой и днем недели по центру
                Button(action: toggleCalendarAction) {
                    VStack(spacing: 0) { 
                        Text(viewModel.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Text(viewModel.formattedWeekday)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
//                    .padding(.vertical, 3)
                    .padding(.bottom, 5)
                    .padding(.leading, 15)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                // Мини-версия WeekCalendarView прямо в TopBar
                WeekCalendarView(selectedDate: .constant(viewModel.selectedDate))
                    .scaleEffect(0.5)
                    .frame(height: 35)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Spacer()
            
            // Кнопка настроек перенесена направо
            if !isCalendarVisible {
                Button(action: showSettingsAction) {
                    Image(systemName: "gear")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                        .padding(.trailing, 16)
                }
                .padding(.bottom, 4)
            } else {
                // Пустой элемент для сохранения структуры при скрытой кнопке
                Color.clear
                    .frame(width: 20)
                    .padding(.trailing, 16)
            }
        }
        .padding(.top, 5)
        // .padding(.bottom, 2)
        .frame(height: 50) // Явно задаем высоту панели, как в стандартном навбаре
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                .padding(.horizontal, 10)
        )
    }
}

#Preview {
    TopBarView(viewModel: ClockViewModel(), showSettingsAction: {}, toggleCalendarAction: {}, isCalendarVisible: false, searchAction: {})
}

