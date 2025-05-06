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

    @State private var dragOffset: CGFloat = 0
    @State private var expandedCalendar = false

    var body: some View {
        ZStack(alignment: .top) {
            // Развернутый календарь
            if expandedCalendar {
                WeekCalendarView(
                    selectedDate: .constant(viewModel.selectedDate),
                    onHideCalendar: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            expandedCalendar = false
                        }
                    }
                )
                .padding(.top, 50)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
            }

            // Основная панель
            HStack {
                // Кнопка поиска слева
                Button(action: searchAction) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .padding(4)
                }
                .background(
                    Circle()
                        .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                )
                .padding(.leading, 16)
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)

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
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                            .padding(4)
                    }
                    .background(
                        Circle()
                            .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    )
                    .padding(.trailing, 16)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                } else {
                    // Пустой элемент для сохранения структуры при скрытой кнопке
                    Color.clear
                        .frame(width: 20)
                        .padding(.trailing, 16)
                }
            }
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                    .padding(.horizontal, 10)
            )
            .offset(y: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Разрешаем свайп только вниз
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height / 3  // Уменьшаем скорость движения
                        }
                    }
                    .onEnded { value in
                        // Если свайп достаточно большой - показываем WeekCalendarView
                        if value.translation.height > 40 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                expandedCalendar = true
                                dragOffset = 0
                            }
                        } else {
                            // Возвращаем в исходное положение
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
            .zIndex(2)
        }
    }
}

#Preview {
    TopBarView(
        viewModel: ClockViewModel(), showSettingsAction: {}, toggleCalendarAction: {},
        isCalendarVisible: false, searchAction: {})
}
