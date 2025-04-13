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
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                if viewModel.selectedCategory != nil {
                    // Показываем список задач для выбранной категории
                    TaskListView(
                        viewModel: listViewModel,
                        selectedCategory: viewModel.selectedCategory
                    )
                    .onAppear {
                        // Обновляем выбранную категорию при появлении
                        listViewModel.selectedCategory = viewModel.selectedCategory
                    }
                    .onChange(of: viewModel.selectedCategory) { newCategory in
                        // Обновляем выбранную категорию при ее изменении
                        listViewModel.selectedCategory = newCategory
                    }
                    .transition(.opacity)
                } else {
                    // Показываем циферблат
                    ZStack {
                        RingPlanner(
                            color: ThemeManager.shared.currentOuterRingColor,
                            viewModel: viewModel,
                            zeroPosition: viewModel.zeroPosition
                        )

                        GlobleClockFaceViewIOS(
                            currentDate: viewModel.selectedDate,
                            tasks: viewModel.tasks,
                            viewModel: viewModel,
                            markersViewModel: viewModel.markersViewModel,
                            draggedCategory: $viewModel.draggedCategory,
                            zeroPosition: viewModel.zeroPosition
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

                // Набор категорий снизу - скрываем при активном поиске
                if !isSearchActive {
                    DockBarIOS(
                        viewModel: viewModel,
                        showingAddTask: $viewModel.showingAddTask,
                        draggedCategory: $viewModel.draggedCategory,
                        showingCategoryEditor: $viewModel.showingCategoryEditor,
                        selectedCategory: $viewModel.selectedCategory
                    )
                    .transition(.move(edge: .bottom))
                }
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
                        Button(action: { viewModel.showingSettings = true }) {
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
            .fullScreenCover(isPresented: $viewModel.showingSettings) {
                SettingsViewIOS()
            }
            .sheet(isPresented: $viewModel.showingCalendar) {
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
        }
        // Подложка цветом циферблата
        .background(ThemeManager.shared.currentClockFaceColor)
        .preferredColorScheme(ThemeManager.shared.isDarkMode ? .dark : .light)
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
        }
        .onDisappear {
            // Удаляем обработчик уведомлений
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("SearchActiveStateChanged"),
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
