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
                
                VStack {
                    Spacer()

                    if viewModel.selectedCategory != nil {
                        // Показываем список задач для выбранной категории
                        VStack(spacing: 0) {
                            // Добавляем отступ сверху
                            // Spacer()
                            //     .frame(height: 30)
                            
                            TaskListView(
                                viewModel: listViewModel,
                                selectedCategory: viewModel.selectedCategory
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
                        .transition(.opacity)
                    } else {
                        // Показываем циферблат
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
                    }

                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack {
                            Text(viewModel.formattedDate)
                                .font(.headline)
                            Text(viewModel.formattedWeekday)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack {
                            Button(action: { showingNewSettings = true }) {
                                Image(systemName: "gear")
                            }
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button(action: { viewModel.showingCalendar = true }) {
                                Image(systemName: "calendar")
                            }
                        }
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
            }
            .fullScreenCover(isPresented: $viewModel.showingCalendar) {
                CalendarView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $viewModel.showingCategoryEditor) {
                CategoryEditorViewIOS(
                    viewModel: viewModel,
                    isPresented: $viewModel.showingCategoryEditor
                )
            }
            .fullScreenCover(isPresented: $viewModel.showingAddTask) {
                // При открытии формы добавления задачи, передаем выбранную категорию
                if let selectedCategory = viewModel.selectedCategory {
                    FormTaskView(viewModel: listViewModel, onDismiss: {
                        viewModel.showingAddTask = false
                    })
                    .onAppear {
                        // Убедимся, что категория правильно передана
                        listViewModel.selectedCategory = selectedCategory
                    }
                }
            }
            // 3. Новый .fullScreenCover
            .fullScreenCover(isPresented: $showingNewSettings) {
                NavigationStack {
                    PersonalizationViewIOS(viewModel: viewModel)
                }
            }
            .background(Color(red: 0.098, green: 0.098, blue: 0.098))
        }
        // .preferredColorScheme(ThemeManager.shared.isDarkMode ? .dark : .light)
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
