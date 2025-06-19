//
//  HeaderView.swift
//  TaskFl0w
//
//  Created by Yan on 4/5/25.
//

import SwiftUI
import UIKit

struct HeaderView: View {
    let viewModel: ClockViewModel
    let showSettingsAction: () -> Void
    let toggleCalendarAction: () -> Void
    let isCalendarVisible: Bool
    let searchAction: () -> Void

    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var isSearchViewPresented = false
    @StateObject private var listViewModel = ListViewModel()

    @State private var dragOffset: CGFloat = 0
    @State private var expandedCalendar = false
    @State private var isBarVisible = true
    @State private var allowMonthCalendarExpansion = false
    @State private var reloadCounter = 0
    @State private var calendarSelectedDate: Date

    init(viewModel: ClockViewModel, showSettingsAction: @escaping () -> Void, toggleCalendarAction: @escaping () -> Void, isCalendarVisible: Bool, searchAction: @escaping () -> Void) {
        self.viewModel = viewModel
        self.showSettingsAction = showSettingsAction
        self.toggleCalendarAction = toggleCalendarAction
        self.isCalendarVisible = isCalendarVisible
        self.searchAction = searchAction
        _calendarSelectedDate = State(initialValue: viewModel.selectedDate)
    }

    // Добавляем функцию для виброотдачи
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Развернутый календарь
            if expandedCalendar {
                WeekCalendarView(
                    selectedDate: $calendarSelectedDate,
                    disableMonthExpansion: !allowMonthCalendarExpansion,
                    initialShowMonthCalendar: false,
                    onHideCalendar: {
                        // Полностью отделяем анимации
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            // Сначала скрываем календарь без анимации
                            expandedCalendar = false
                            
                            // Затем с задержкой показываем TopBar
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isBarVisible = true
                                }
                            }
                        }
                    }
                )
                .padding(.top, isBarVisible ? 50 : 0)
                .transition(.opacity)
                .zIndex(1)
                .id(reloadCounter)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        allowMonthCalendarExpansion = true
                    }
                }
                .onChange(of: calendarSelectedDate) { _, newValue in
                    viewModel.selectedDate = newValue
                    // Возможно, потребуется вызвать другие методы для обновления данных
                }
            }

            // Основная панель
            if isBarVisible {
                HStack {
                    // Кнопка поиска слева
                    Button(action: {
                        hapticFeedback()
                        isSearchViewPresented = true
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundColor(themeManager.isDarkMode ? .coral1 : .red1)
                            .padding(4)
                            .frame(width: 35, height: 35)
                    }
                    .background(
                        Circle()
                            .fill(themeManager.isDarkMode ? Color(red: 0.184, green: 0.184, blue: 0.184) : Color(red: 0.95, green: 0.95, blue: 0.95))
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
                    .opacity(0.8)

                    Spacer()

                    // Здесь отображаем либо информацию о дате, либо мини-календарь
                    if !isCalendarVisible {
                        // Отображаем дату и день недели (без кнопки)
                        VStack(spacing: 0) {
                            Text(viewModel.formattedDate)
                                .font(.subheadline)
                                .foregroundColor(themeManager.isDarkMode ? .primary : .black)
                            Text(viewModel.formattedWeekday)
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .secondary : .gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        // Мини-версия WeekCalendarView прямо в TopBar
                        WeekCalendarView(
                            selectedDate: $calendarSelectedDate,
                            disableMonthExpansion: true
                        )
                            .scaleEffect(0.5)
                            .frame(height: 35)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    Spacer()

                    // Кнопка настроек перенесена направо
                    if !isCalendarVisible {
                        Button(action: {
                            hapticFeedback()
                            showSettingsAction()
                        }) {
                            Image(systemName: "gear")
                                .font(.system(size: 20))
                                .foregroundColor(themeManager.isDarkMode ? .coral1 : .red1)
                                .padding(4)
                                .frame(width: 35, height: 35)
                        }
                        .background(
                            Circle()
                                .fill(themeManager.isDarkMode ? Color(red: 0.184, green: 0.184, blue: 0.184) : Color(red: 0.95, green: 0.95, blue: 0.95))
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
                        .fill(themeManager.isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 0.95, green: 0.95, blue: 0.95))
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
                            // Если свайп достаточно большой - скрываем TopBar и показываем WeekCalendarView
                            if value.translation.height > 40 {
                                // Увеличиваем счетчик для пересоздания WeekCalendarView
                                reloadCounter += 1
                                
                                // Сначала скрываем TopBar без анимации
                                isBarVisible = false
                                
                                // Затем с задержкой показываем календарь
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        expandedCalendar = true
                                        dragOffset = 0
                                    }
                                }
                            } else {
                                // Возвращаем в исходное положение с простой анимацией
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                .zIndex(2)
                .transition(.opacity)
            }
        }
        .fullScreenCover(isPresented: $isSearchViewPresented) {
            SearchView(
                items: listViewModel.items,
                categoryColor: .blue,
                isSelectionMode: false,
                selectedTasks: .constant([]),
                onToggle: { taskId in
                    listViewModel.presenter?.toggleItem(id: taskId)
                },
                onEdit: { task in
                    listViewModel.presenter?.editItem(id: task.id, title: task.title)
                },
                onDelete: { taskId in
                    listViewModel.presenter?.deleteItem(id: taskId)
                },
                onShare: { taskId in
                    listViewModel.presenter?.shareItem(id: taskId)
                },
                categoryManagement: viewModel.categoryManagement
            )
            .onAppear {
                // Принудительно обновляем данные при открытии поиска
                listViewModel.refreshData()
                listViewModel.onViewDidLoad()
            }
        }
    }
}

#Preview {
    HeaderView(
        viewModel: ClockViewModel(), showSettingsAction: {}, toggleCalendarAction: {},
        isCalendarVisible: false, searchAction: {})
}
