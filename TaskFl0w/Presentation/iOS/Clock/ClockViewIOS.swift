//
//  ClockViewIOS.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI
import Combine

// Группируем связанные состояния в структуры
struct ClockViewState {
    var isSearchActive = false
    var isDockBarHidden = false
    var isOutsideArea = false
    var showingNewSettings = false
    var showingTaskTimeline = false
    var showingWeekCalendar = false
}

struct DragState {
    var offset: CGSize = .zero
    var isDragging = false
}

struct ZoomState {
    var scale: CGFloat = 1.0
    var focusOffset: CGPoint = .zero
}

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
    
    // Добавляем свойство для хранения подписок
    @State private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Фоновая область для обнаружения перетаскивания за пределы часов
                DropZoneView(isTargeted: $isOutsideArea,
                             onEntered: {
                                 print("⚠️ [ClockViewIOS] Объект перетаскивания обнаружен во внешней зоне")
                                 if let task = viewModel.draggedTask {
                                     print("⚠️ [ClockViewIOS] Это задача \(task.id)")
                                     viewModel.taskManagement.removeTask(task)
                                 }
                             },
                             onExited: {
                                 print("⚠️ [ClockViewIOS] Объект покинул внешнюю зону")
                             }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)
                
                VStack(spacing: 0) {
                    // Удаляем верхнюю панель отсюда и оставляем только WeekCalendarView
                    if showingWeekCalendar {
                        // Используем обновленную WeekCalendarView с коллбэком
                        WeekCalendarView(
                            selectedDate: $viewModel.selectedDate,
                            onHideCalendar: {
                                showingWeekCalendar = false
                            }
                        )
                    }
                    
                    if viewModel.selectedCategory != nil {
                        // Показываем список задач для выбранной категории
                        VStack(spacing: 0) {
                            // Верхний Spacer только для режима списка задач
                            Spacer()
                                .frame(height: 20)
                            
                            TaskListView(
                                viewModel: listViewModel,
                                selectedCategory: viewModel.selectedCategory,
                                selectedDate: $viewModel.selectedDate
                            )
                            .background(themeManager.isDarkMode 
                                ? Color(red: 0.098, green: 0.098, blue: 0.098) 
                                : Color(red: 0.95, green: 0.95, blue: 0.95))
                            .onAppear {
                                // Обновляем выбранную категорию при появлении
                                listViewModel.selectedCategory = viewModel.selectedCategory
                            }
                            .onChange(of: viewModel.selectedCategory) { oldValue, newValue in
                                // Обновляем выбранную категорию при ее изменении
                                listViewModel.selectedCategory = newValue
                            }
                            
                            // Добавляем отступ снизу
                            Spacer()
                                .frame(height: 50)
                        }
                        .background(themeManager.isDarkMode 
                            ? Color(red: 0.098, green: 0.098, blue: 0.098) 
                            : Color(red: 0.95, green: 0.95, blue: 0.95))
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedCategory)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // Обрабатываем только вертикальное перемещение вниз
                                    if value.translation.height > 0 && value.startLocation.y < 100 {
                                        // Начало жеста в верхней части экрана
                                        isDragging = true
                                        dragOffset = value.translation
                                    }
                                }
                                .onEnded { value in
                                    // Если свайп вниз больше 80 пикселей и начался в верхней части экрана
                                    if value.translation.height > 80 && value.startLocation.y < 100 {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            // Закрываем список задач и очищаем выбранную категорию
                                            viewModel.selectedCategory = nil
                                        }
                                    }
                                    
                                    // В любом случае сбрасываем смещение
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        isDragging = false
                                        dragOffset = .zero
                                    }
                                }
                        )
                    } else {
                        // Показываем циферблат - поднимаем на 20 пикселей выше центра
                        Spacer()
                        
                        ZStack {
                            // Заменяем RingPlanner на модифицированную версию без удаления задачи
                            RingPlanner(
                                color: ThemeManager.shared.currentOuterRingColor,
                                viewModel: viewModel,
                                zeroPosition: viewModel.zeroPosition,
                                shouldDeleteTask: false,
                                outerRingLineWidth: viewModel.outerRingLineWidth
                            )

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
                            showSettingsAction: { showingNewSettings = true },
                            toggleCalendarAction: toggleWeekCalendar,
                            isCalendarVisible: showingWeekCalendar,
                            searchAction: { 
                            // Здесь добавляем логику поиска
                        }
                        )
                        Spacer()
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        handleDragGesture(value)
                    }
                    .onEnded { value in
                        handleDragGestureEnd(value)
                    }
            )
            .fullScreenCover(isPresented: $viewModel.showingCategoryEditor) {
                CategoryEditorViewIOS(
                    viewModel: viewModel,
                    isPresented: $viewModel.showingCategoryEditor
                )
            }
            .fullScreenCover(isPresented: $showingNewSettings) {
                NavigationStack {
                    PersonalizationViewIOS(viewModel: viewModel)
                }
            }
            .horizontalFullScreenCover(isPresented: $showingTaskTimeline) {
                TaskTimeline(
                    selectedDate: viewModel.selectedDate,
                    tasks: viewModel.tasks,
                    listViewModel: listViewModel,
                    categoryManager: viewModel.categoryManagement
                )
            }
            .background(themeManager.isDarkMode ? Color(red: 0.098, green: 0.098, blue: 0.098) : Color(red: 0.95, green: 0.95, blue: 0.95))
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onReceive(timer) { _ in
            viewModel.updateCurrentTimeIfNeeded()
        }
        .onAppear {
            // Обновляем интерфейс при первом появлении
            initializeUI()
            
            // Регистрируем обработчик уведомлений для отслеживания состояния поиска
            registerNotifications()
        }
        .onDisappear {
            // Удаляем обработчики уведомлений
            unregisterNotifications()
        }
        .onChange(of: viewModel.isEditingMode) { oldValue, newValue in
            updateUI()
        }
        .onChange(of: viewModel.editingTask) { oldValue, newValue in
            updateUI()
        }
        .onChange(of: viewModel.previewTime) { oldValue, newValue in
            // Обновляем масштаб при перетаскивании маркеров задачи (изменение длительности)
            if viewModel.isEditingMode && (viewModel.isDraggingStart || viewModel.isDraggingEnd) {
                updateUI()
            }
        }
    }
    
    // Функция для переключения отображения недельного календаря
    private func toggleWeekCalendar() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showingWeekCalendar.toggle()
        }
    }
    
    // MARK: - Инициализация при первом появлении
    private func initializeUI() {
        viewModel.markersViewModel.numbersSize = viewModel.numbersSize
        viewModel.updateUIForThemeChange()
        viewModel.updateMarkersViewModel()
    }
    
    // Обработчик изменения редактируемой задачи
    private func updateUI() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if viewModel.isEditingMode, let task = viewModel.editingTask {
                let (scale, offset) = calculateZoomScale(for: task)
                zoomScale = scale
                focusOffset = offset
            } else {
                zoomScale = 1.0
                focusOffset = .zero
            }
        }
    }
    
    // Заменяем метод registerNotifications на новый
    private func registerNotifications() {
        // Обработка состояния поиска
        NotificationCenter.default.publisher(for: NSNotification.Name("SearchActiveStateChanged"))
            .compactMap { notification -> Bool? in
                notification.userInfo?["isActive"] as? Bool
            }
            .receive(on: DispatchQueue.main)
            .sink { isActive in
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.isSearchActive = isActive
                }
            }
            .store(in: &cancellables)
        
        // Обработка видимости докбара
        NotificationCenter.default.publisher(for: NSNotification.Name("DockBarVisibilityChanged"))
            .compactMap { notification -> Bool? in
                notification.userInfo?["isVisible"] as? Bool
            }
            .receive(on: DispatchQueue.main)
            .sink { isVisible in
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.isDockBarHidden = !isVisible
                }
            }
            .store(in: &cancellables)
        
        // Обработка закрытия временной шкалы
        NotificationCenter.default.publisher(for: NSNotification.Name("CloseTaskTimeline"))
            .receive(on: DispatchQueue.main)
            .sink { _ in
                withAnimation {
                    self.showingTaskTimeline = false
                }
            }
            .store(in: &cancellables)
        
        // Обработка изменения стиля часов
        NotificationCenter.default.publisher(for: NSNotification.Name("ClockStyleDidChange"))
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.viewModel.applyWatchFaceSettings()
            }
            .store(in: &cancellables)
        
        // Обработка применения циферблата
        NotificationCenter.default.publisher(for: NSNotification.Name("WatchFaceApplied"))
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.viewModel.applyWatchFaceSettings()
            }
            .store(in: &cancellables)
    }
    
    // Заменяем метод unregisterNotifications на новый
    private func unregisterNotifications() {
        cancellables.removeAll()
    }
    
    private func calculateZoomScale(for task: TaskOnRing) -> (scale: CGFloat, offset: CGPoint) {
        let durationHours = task.duration / 3600
        
        if durationHours >= 1 {
            return (1.0, .zero)
        }
        
        let minDuration: Double = 10 * 60
        let maxDuration: Double = 1 * 3600
        let minScale: CGFloat = 1.0
        let maxScale: CGFloat = 1.7
        
        let limitedDuration = max(minDuration, task.duration)
        let normalizedDuration = 1 - ((limitedDuration - minDuration) / (maxDuration - minDuration))
        let scale = minScale + normalizedDuration * (maxScale - minScale)
        
        let startAngle = viewModel.timeToAngle(task.startTime)
        let endAngle = viewModel.timeToAngle(task.endTime)
        let midAngle = (startAngle + endAngle) / 2.0
        let midAngleRadians = midAngle * .pi / 180.0
        
        let approximateRadius: CGFloat = 150
        let scaleFactor = scale - 1.0
        let offsetX = cos(midAngleRadians) * approximateRadius * scaleFactor
        let offsetY = sin(midAngleRadians) * approximateRadius * scaleFactor
        
        return (scale, CGPoint(x: offsetX, y: offsetY))
    }
    
    private func handleDragGesture(_ value: DragGesture.Value) {
        if value.translation.width < 0 && !showingWeekCalendar && !viewModel.isEditingMode {
            isDragging = true
            dragOffset = value.translation
        }
    }
    
    private func handleDragGestureEnd(_ value: DragGesture.Value) {
        if value.translation.width < -100 && !showingWeekCalendar && !viewModel.isEditingMode {
            withAnimation {
                showingTaskTimeline = true
            }
        }
        
        withAnimation(.spring()) {
            isDragging = false
            dragOffset = .zero
        }
    }
    
    private func updateState() {
        if viewModel.isEditingMode {
            updateUI()
        }
    }
}

#Preview {
    ClockViewIOS()
}
