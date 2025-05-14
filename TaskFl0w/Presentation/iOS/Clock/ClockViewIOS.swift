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
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
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
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(y: -50) // Сдвигаем циферблат на 50 пикселей вверх
                        .offset(x: dragOffset.width < 0 ? dragOffset.width : 0) // Добавляем смещение при свайпе влево
                        .animation(.spring(), value: isDragging) // Анимация при перетаскивании
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
                        // Блокируем жест свайпа, если активен режим редактирования задачи
                        if value.translation.width < 0 && !showingWeekCalendar && !viewModel.isEditingMode {
                            isDragging = true
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        // Если свайп влево больше 100 пикселей (по модулю), показываем TaskTimeline,
                        // только если не активен режим редактирования задачи
                        if value.translation.width < -100 && !showingWeekCalendar && !viewModel.isEditingMode {
                            withAnimation {
                                showingTaskTimeline = true
                            }
                        }
                        
                        // В любом случае сбрасываем смещение
                        withAnimation(.spring()) {
                            isDragging = false
                            dragOffset = .zero
                        }
                    }
            )
//            .fullScreenCover(isPresented: $viewModel.showingCalendar) {
//                CalendarView(viewModel: viewModel)
//            }
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
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("SearchActiveStateChanged"),
                object: nil,
                queue: .main
            ) { notification in
                if let isActive = notification.userInfo?["isActive"] as? Bool {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.isSearchActive = isActive
                    }
                }
            }
            
            // Добавляем обработчик для видимости докбара
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("DockBarVisibilityChanged"),
                object: nil,
                queue: .main
            ) { notification in
                if let isVisible = notification.userInfo?["isVisible"] as? Bool {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.isDockBarHidden = !isVisible
                    }
                }
            }
            
            // Добавляем обработчик для закрытия TaskTimeline по свайпу
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("CloseTaskTimeline"),
                object: nil,
                queue: .main
            ) { _ in
                withAnimation {
                    self.showingTaskTimeline = false
                }
            }
        }
        .onDisappear {
            // Удаляем обработчики уведомлений
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("SearchActiveStateChanged"),
                object: nil
            )
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("DockBarVisibilityChanged"),
                object: nil
            )
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("CloseTaskTimeline"),
                object: nil
            )
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
        // Убедимся, что размер цифр правильно инициализирован
        viewModel.markersViewModel.numbersSize = viewModel.numbersSize
        
        // Обновляем интерфейс при первом появлении
        viewModel.updateUIForThemeChange()
        
        // Принудительно обновляем представление маркеров
        viewModel.updateMarkersViewModel()
    }
}

#Preview {
    ClockViewIOS()
}
