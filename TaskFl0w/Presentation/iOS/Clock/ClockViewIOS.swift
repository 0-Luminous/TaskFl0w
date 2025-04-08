//
//  ClockViewIOS.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct ClockViewIOS: View {
    @StateObject private var viewModel = ClockViewModel()
    
    // Таймер для "реал-тайм" обновления
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                if viewModel.selectedCategory != nil {
                    // Показываем список задач для выбранной категории
                    TaskListView(
                        viewModel: ListViewModel(), selectedCategory: viewModel.selectedCategory
                    )
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
        .background(ThemeManager.shared.currentClockFaceColor)
        .preferredColorScheme(ThemeManager.shared.isDarkMode ? .dark : .light)
        .onReceive(timer) { _ in
            viewModel.updateCurrentTimeIfNeeded()
        }
        .onAppear {
            // Обновляем интерфейс при первом появлении
            initializeUI()
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
