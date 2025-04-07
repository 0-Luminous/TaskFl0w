//
//  ClockViewIOS.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct ClockViewIOS: View {
    @StateObject private var viewModel = ClockViewModel()
    @StateObject private var markersViewModel = ClockMarkersViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared

    @Environment(\.colorScheme) var colorScheme

    // Таймер для "реал-тайм" обновления
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @AppStorage("lightModeOuterRingColor") private var lightModeOuterRingColor: String = Color.gray
        .opacity(0.3).toHex()
    @AppStorage("darkModeOuterRingColor") private var darkModeOuterRingColor: String = Color.gray
        .opacity(0.3).toHex()
    @AppStorage("zeroPosition") private var zeroPosition: Double = 0.0

    // AppStorage для маркеров
    @AppStorage("showHourNumbers") private var showHourNumbers: Bool = true
    @AppStorage("markersWidth") private var markersWidth: Double = 2.0
    @AppStorage("markersOffset") private var markersOffset: Double = 40.0
    @AppStorage("numbersSize") private var numbersSize: Double = 12.0
    @AppStorage("lightModeMarkersColor") private var lightModeMarkersColor: String = Color.gray
        .toHex()
    @AppStorage("darkModeMarkersColor") private var darkModeMarkersColor: String = Color.gray
        .toHex()

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
                            color: themeManager.currentOuterRingColor,
                            viewModel: viewModel,
                            zeroPosition: zeroPosition
                        )

                        GlobleClockFaceViewIOS(
                            currentDate: viewModel.selectedDate,
                            tasks: viewModel.tasks,
                            viewModel: viewModel,
                            markersViewModel: markersViewModel,
                            draggedCategory: $viewModel.draggedCategory,
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
        .background(themeManager.currentClockFaceColor)
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
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
            
            // Гарантируем, что ViewModel использует правильное значение темы
            viewModel.isDarkMode = themeManager.isDarkMode
            markersViewModel.isDarkMode = themeManager.isDarkMode

            // Обновляем интерфейс для текущей темы
            updateUIForThemeChange()
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
        .onChange(of: themeManager.isDarkMode) { _, newValue in
            markersViewModel.isDarkMode = newValue
            updateUIForThemeChange()
        }
    }

    // MARK: - Вспомогательные вычислимые свойства

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
    
    private func updateUIForThemeChange() {
        // Гарантируем, что UI обновится при смене темы
        DispatchQueue.main.async {
            // Передаем статус темной темы из ThemeManager в ViewModel
            if viewModel.isDarkMode != themeManager.isDarkMode {
                viewModel.isDarkMode = themeManager.isDarkMode
            }
            if markersViewModel.isDarkMode != themeManager.isDarkMode {
                markersViewModel.isDarkMode = themeManager.isDarkMode
            }
            
            // Принудительно обновляем UI
            markersViewModel.updateCurrentThemeColors()
            
            // Обновляем свойства моделей, которые вызовут обновление представления
            viewModel.objectWillChange.send()
            markersViewModel.objectWillChange.send()
        }
    }
}

#Preview {
    ClockViewIOS()
}
