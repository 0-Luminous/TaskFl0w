//
//  ClockViewIOS.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct ClockViewIOS: View {
    @StateObject var viewModel = ClockViewModel()
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Создаем ListViewModel один раз для многократного использования
    @StateObject private var listViewModel = ListViewModel()
    
    // Состояние активности поиска
    @State private var isSearchActive = false
    
    // Состояние видимости докбара
    @State private var isDockBarHidden = false
    
    // Состояние для отслеживания объекта вне часов
    @State private var isOutsideArea: Bool = false
    
    // 1. Новое состояние
    @State private var showingNewSettings = false
    
    // Состояние для отображения TaskTimeline
    @State private var showingTaskTimeline = false
    
    // Состояние для обработки свайпа
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    // Состояние для отображения недельного календаря
    @State private var showingWeekCalendar = false
    
    // Состояние для масштабирования циферблата
    @State private var zoomScale: CGFloat = 1.0
    
    // Состояние для смещения циферблата к редактируемой задаче
    @State private var focusOffset: CGPoint = CGPoint(x: 0, y: 0)
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                            GlobleClockFaceViewIOS(
                                currentDate: viewModel.selectedDate,
                                tasks: viewModel.tasks,
                                viewModel: viewModel,
                                markersViewModel: viewModel.markersViewModel,
                                draggedCategory: $viewModel.draggedCategory,
                                zeroPosition: viewModel.zeroPosition,
                                taskArcLineWidth: viewModel.isAnalogArcStyle ? viewModel.outerRingLineWidth : viewModel.taskArcLineWidth,
                                outerRingLineWidth: viewModel.outerRingLineWidth
                            )

                            if viewModel.isEditingMode, let editingTask = viewModel.editingTask {
                                TimeTaskEditorOverlay(
                                    viewModel: viewModel,
                                    task: editingTask
                                )
                            }
                            
                            // Показываем индикатор приближения
                            if zoomScale > 1.01 {
                                VStack {
                                    Spacer()
                                    
                                    // Text("Нажмите на задачу для выхода из режима приближения")
                                    //     .font(.system(size: 12))
                                    //     .foregroundColor(.gray)
                                    //     .padding(8)
                                    //     .background(
                                    //         Capsule()
                                    //             .fill(.ultraThinMaterial)
                                    //             .overlay(
                                    //                 Capsule()
                                    //                     .stroke(
                                    //                         LinearGradient(
                                    //                             colors: [.white.opacity(0.5), .clear],
                                    //                             startPoint: .top,
                                    //                             endPoint: .bottom
                                    //                         ),
                                    //                         lineWidth: 1
                                    //                     )
                                    //             )
                                    //     )
                                    //     .padding(.bottom, 20)
                                    //     .transition(.opacity)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(y: -50) // Сдвигаем циферблат на 50 пикселей вверх
                        .offset(x: dragOffset.width < 0 ? dragOffset.width : 0) // Добавляем смещение при свайпе влево
                        .offset(x: focusOffset.x, y: focusOffset.y) // Добавляем смещение для фокусировки
                        .scaleEffect(zoomScale) // Применяем масштабирование
                        .animation(.spring(), value: isDragging) // Анимация при перетаскивании
                        .animation(.spring(), value: zoomScale) // Анимация при масштабировании
                        .animation(.spring(), value: focusOffset) // Анимация при смещении фокуса
                    }
                }
                
                // Набор категорий снизу - скрываем при активном поиске или при создании задачи
                
                if !isSearchActive && !isDockBarHidden {
                    VStack {
                        Spacer()
                        DockBarIOS(viewModel: viewModel.dockBarViewModel)
                            .transition(.move(edge: .bottom))
                    }
                    
                }
                
                // Добавляем TopBarView поверх всех элементов, если не показан WeekCalendar
                if !showingWeekCalendar {
                    VStack {
                        TopBarView(
                            viewModel: viewModel,
                            zeroPosition: zeroPosition
                        )

                        GlobleClockFaceViewIOS(
                            currentDate: viewModel.selectedDate,
                            tasks: viewModel.tasks,
                            viewModel: viewModel,
                            markersViewModel: markersViewModel,
                            draggedCategory: $viewModel.draggedCategory,
                            clockFaceColor: currentClockFaceColor,
                            zeroPosition: zeroPosition
                        )

                        if viewModel.isEditingMode, let editingTask = viewModel.editingTask {
                            TimeTaskEditorOverlay(
                                viewModel: viewModel,
                                task: editingTask
                            )
                        }
                        //                        CircularNavigationOverlay(
                        //                            onPreviousDay: {},
                        //                            onNextDay: {}
                        //                            //isDraggingOver: .constant(nil)
                        //                        )
                    }
                }

                Spacer()

                // Набор категорий снизу
                DockBarIOS(
                    viewModel: viewModel,
                    showingAddTask: $viewModel.showingAddTask,
                    draggedCategory: $viewModel.draggedCategory,
                    showingCategoryEditor: $viewModel.showingCategoryEditor,
                    selectedCategory: $viewModel.selectedCategory
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(formattedDate)
                            .font(.headline)
                        Text(formattedWeekday)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button(action: { viewModel.showingSettings = true }) {
                            Image(systemName: "gear")
                        }
                        Button(action: { viewModel.showingStatistics = true }) {
                            Image(systemName: "chart.bar")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { viewModel.showingCalendar = true }) {
                            Image(systemName: "calendar")
                        }
                        if viewModel.selectedCategory != nil {
                            Button(action: {
                                withAnimation {
                                    viewModel.selectedCategory = nil
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                            }
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.showingSettings) {
                SettingsViewIOS()
            }
            .sheet(isPresented: $viewModel.showingCalendar) {
                CalendarView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingStatistics) {
                StatisticsView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $viewModel.showingCategoryEditor) {
                // CategoryEditorView, например
                CategoryEditorViewIOS(
                    viewModel: viewModel,
                    isPresented: $viewModel.showingCategoryEditor
                )
            }
        }
        // Подложка цветом циферблата
        .background(currentClockFaceColor)
        .preferredColorScheme(viewModel.isDarkMode ? .dark : .light)
        .onReceive(timer) { _ in
            // Если выбранная дата совпадает с сегодня, тогда обновляем "currentDate" каждую секунду
            if Calendar.current.isDate(viewModel.selectedDate, inSameDayAs: Date()) {
                viewModel.currentDate = Date()
            }
        }
        .onAppear {
            // Инициализируем начальные значения для markersViewModel
            markersViewModel.showHourNumbers = showHourNumbers
            markersViewModel.markersWidth = markersWidth
            markersViewModel.markersOffset = markersOffset
            markersViewModel.numbersSize = numbersSize
            markersViewModel.lightModeMarkersColor = lightModeMarkersColor
            markersViewModel.darkModeMarkersColor = darkModeMarkersColor
            markersViewModel.isDarkMode = viewModel.isDarkMode
        }
        .onChange(of: showHourNumbers) { _, newValue in
            markersViewModel.showHourNumbers = newValue
        }
        .onChange(of: markersWidth) { _, newValue in
            markersViewModel.markersWidth = newValue
        }
        .onChange(of: markersOffset) { _, newValue in
            markersViewModel.markersOffset = newValue
        }
        .onChange(of: numbersSize) { _, newValue in
            markersViewModel.numbersSize = newValue
        }
        .onChange(of: lightModeMarkersColor) { _, newValue in
            markersViewModel.lightModeMarkersColor = newValue
            updateMarkersViewModel()
        }
        .onChange(of: darkModeMarkersColor) { _, newValue in
            markersViewModel.darkModeMarkersColor = newValue
            updateMarkersViewModel()
        }
        .onChange(of: viewModel.isDarkMode) { _, newValue in
            markersViewModel.isDarkMode = newValue
            updateMarkersViewModel()
        }
        .onChange(of: viewModel.isEditingMode) { oldValue, newValue in
            updateZoomForEditingTask()
        }
        .onChange(of: viewModel.editingTask) { oldValue, newValue in
            updateZoomForEditingTask()
        }
        .onChange(of: viewModel.previewTime) { oldValue, newValue in
            // Обновляем масштаб при перетаскивании маркеров задачи (изменение длительности)
            if viewModel.isEditingMode && (viewModel.isDraggingStart || viewModel.isDraggingEnd) {
                updateZoomForEditingTask()
            }
        }
    }

    // MARK: - Вспомогательные вычислимые свойства

    private var currentClockFaceColor: Color {
        let hexColor =
            colorScheme == .dark
            ? viewModel.darkModeClockFaceColor
            : viewModel.lightModeClockFaceColor
        return Color(hex: hexColor) ?? .white
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: viewModel.selectedDate)
    }

    private var formattedWeekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: viewModel.selectedDate).capitalized
    }

    private var currentOuterRingColor: Color {
        let hexColor = colorScheme == .dark ? darkModeOuterRingColor : lightModeOuterRingColor
        return Color(hex: hexColor) ?? .gray.opacity(0.3)
    }

    private func updateMarkersViewModel() {
        // Создаем временное обновление для принудительного обновления вида
        DispatchQueue.main.async {
            let tempValue = markersViewModel.markersWidth
            markersViewModel.markersWidth = tempValue + 0.01
            DispatchQueue.main.async {
                markersViewModel.markersWidth = tempValue
            }
        }
    }
    
    // Обработчик изменения редактируемой задачи
    private func updateZoomForEditingTask() {
        if viewModel.isEditingMode, let task = viewModel.editingTask {
            // Проверяем длительность задачи в часах
            let durationHours = task.duration / 3600
            
            // Если длительность меньше 2 часов, увеличиваем масштаб и фокусируем на задаче
            if durationHours < 2 {
                // Вычисляем масштаб: чем меньше длительность, тем больше масштаб
                // Минимальная длительность (10 минут) -> масштаб 1.8
                // Длительность 2 часа -> масштаб 1.0
                let minDuration: Double = 10 * 60 // 10 минут в секундах
                let maxDuration: Double = 2 * 3600 // 2 часа в секундах
                let minScale: CGFloat = 1.0
                let maxScale: CGFloat = 1.5
                
                // Ограничиваем длительность минимальным значением
                let limitedDuration = max(minDuration, task.duration)
                
                // Рассчитываем относительное положение длительности между минимальной и максимальной
                let normalizedDuration = 1 - ((limitedDuration - minDuration) / (maxDuration - minDuration))
                
                // Вычисляем итоговый масштаб
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    zoomScale = minScale + normalizedDuration * (maxScale - minScale)
                    
                    // Рассчитываем угол для центра задачи
                    // Находим среднюю точку дуги задачи
                    let startAngle = viewModel.timeToAngle(task.startTime)
                    let endAngle = viewModel.timeToAngle(task.endTime)
                    let midAngle = (startAngle + endAngle) / 2.0
                    
                    // Конвертируем угол в радианы (SwiftUI использует радианы)
                    let midAngleRadians = midAngle * .pi / 180.0
                    
                    // Приблизительный радиус циферблата (без использования UIScreen)
                    let approximateRadius: CGFloat = 150
                    
                    // Рассчитываем смещение в направлении задачи, чтобы центрировать её
                    // Разбиваем вычисление на более простые выражения
                    let scaleFactor = zoomScale - 1.0
                    // Инвертируем направление смещения, убирая знак минус
                    let offsetX = cos(midAngleRadians) * approximateRadius * scaleFactor
                    let offsetY = sin(midAngleRadians) * approximateRadius * scaleFactor
                    
                    focusOffset = CGPoint(x: offsetX, y: offsetY)
                }
            } else {
                // Длительность больше или равна 2 часам, используем нормальный масштаб
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    zoomScale = 1.0
                    focusOffset = CGPoint(x: 0, y: 0)
                }
            }
        } else {
            // Нет редактируемой задачи, используем нормальный масштаб
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                zoomScale = 1.0
                focusOffset = CGPoint(x: 0, y: 0)
            }
        }
    }
}

#Preview {
    ClockViewIOS()
}
