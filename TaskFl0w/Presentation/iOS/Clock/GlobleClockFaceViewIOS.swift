//
//  MainClockFaceViewIOS.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct GlobleClockFaceViewIOS: View {
    let currentDate: Date
    let tasks: [TaskOnRing]
    @ObservedObject var viewModel: ClockViewModel
    @ObservedObject var markersViewModel: ClockMarkersViewModel
    @ObservedObject private var themeManager = ThemeManager.shared

    @Binding var draggedCategory: TaskCategoryModel?
    let zeroPosition: Double
    let taskArcLineWidth: CGFloat
    let outerRingLineWidth: CGFloat

    // Добавляем новый параметр
    var isNavigationOverlayVisible: Bool = false

    @Environment(\.colorScheme) var colorScheme
    @AppStorage("clockStyle") private var clockStyle: ClockStyle = .classic
    @AppStorage("markersOffset") private var markersOffset: Double = 0.0
    @AppStorage("numberInterval") private var numberInterval: Int = 1
    @AppStorage("markersWidth") private var markersWidth: Double = 2.0
    @AppStorage("numbersSize") private var numbersSize: Double = 16.0

    // Локальные состояния убраны и перенесены в ViewModel
    // Используем состояния из ViewModel через viewModel

    var body: some View {
        ZStack {
            Circle()
                .fill(themeManager.currentClockFaceColor)
                .stroke(Color.gray, lineWidth: 2)

            // Маркеры часов (24 шт.) - без цифр
            if markersViewModel.showMarkers {
                ForEach(0..<24, id: \.self) { hour in
                    let angle = Double(hour) * (360.0 / 24.0)
                    ClockMarker(
                        hour: hour,
                        style: clockStyle.markerStyle,
                        viewModel: markersViewModel,
                        MarkersColor: themeManager.currentMarkersColor,
                        zeroPosition: zeroPosition,
                        showNumbers: false // Не показываем цифры на этом слое
                    )
                    .rotationEffect(.degrees(angle))
                    .frame(
                        width: UIScreen.main.bounds.width * 0.7,
                        height: UIScreen.main.bounds.width * 0.7)
                    // Добавляем идентификатор для принудительной переотрисовки при изменении zeroPosition
                    .id("marker-\(hour)-\(Int(zeroPosition))")
                }
            }
            
            // Слой с цифрами (отдельно) - показываем независимо от маркеров
            if markersViewModel.showHourNumbers {
                ForEach(0..<24, id: \.self) { hour in
                    let angle = Double(hour) * (360.0 / 24.0)
                    // Проверяем, нужно ли отображать число в соответствии с интервалом
                    if shouldShowHourNumber(hour: hour) {
                        HourNumberView(
                            hour: hour,
                            viewModel: markersViewModel,
                            color: themeManager.currentMarkersColor,
                            zeroPosition: zeroPosition
                        )
                        .rotationEffect(.degrees(angle))
                        .frame(
                            width: UIScreen.main.bounds.width * 0.7,
                            height: UIScreen.main.bounds.width * 0.7)
                        // Добавляем идентификатор для принудительной переотрисовки
                        .id("hour-number-\(hour)-\(Int(zeroPosition))")
                    }
                }
            }

            TaskArcsViewIOS(
                tasks: viewModel.tasksForSelectedDate(tasks),
                viewModel: viewModel,
                arcLineWidth: taskArcLineWidth
            )

            ClockHandViewIOS(currentDate: viewModel.currentDate, outerRingLineWidth: outerRingLineWidth)
                .rotationEffect(.degrees(zeroPosition))

            // Показ точки, куда «кидаем» категорию
            if let location = viewModel.dropLocation {
                Circle()
                    .fill(viewModel.draggedCategory?.color ?? .clear)
                    .frame(width: 20, height: 20)
                    .position(location)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(height: UIScreen.main.bounds.width * 0.7)
        .padding()
        .animation(.spring(), value: viewModel.tasksForSelectedDate(tasks))
        .animation(.spring(), value: markersViewModel.showMarkers)
        .animation(.spring(), value: markersViewModel.showHourNumbers)
        .onAppear {
            markersViewModel.zeroPosition = zeroPosition
            markersViewModel.isDarkMode = themeManager.isDarkMode
            markersViewModel.numberInterval = numberInterval
            markersViewModel.markersOffset = markersOffset
            markersViewModel.markersWidth = markersWidth
            markersViewModel.numbersSize = numbersSize
            // Принудительно обновляем View
            updateMarkersViewModel()
        }
        .onChange(of: zeroPosition) { oldValue, newValue in
            markersViewModel.zeroPosition = newValue
        }
        .onChange(of: themeManager.isDarkMode) { oldValue, newValue in
            markersViewModel.isDarkMode = newValue
        }
        .onChange(of: numberInterval) { oldValue, newValue in
            markersViewModel.numberInterval = newValue
        }
        .onChange(of: markersOffset) { oldValue, newValue in
            markersViewModel.markersOffset = newValue
            updateMarkersViewModel()
        }
        .onChange(of: markersWidth) { oldValue, newValue in
            markersViewModel.markersWidth = newValue
            updateMarkersViewModel()
        }
        .onChange(of: numbersSize) { oldValue, newValue in
            markersViewModel.numbersSize = newValue
            updateMarkersViewModel()
        }
    }

    // Метод для принудительного обновления представления маркеров
    private func updateMarkersViewModel() {
        let tempWidth = markersViewModel.markersWidth
        DispatchQueue.main.async {
            // Создаем небольшое временное изменение, чтобы View обновилось
            markersViewModel.markersWidth = tempWidth + 0.01
            DispatchQueue.main.async {
                markersViewModel.markersWidth = tempWidth
            }
        }
    }

    // Вспомогательная функция для определения, нужно ли показывать число
    private func shouldShowHourNumber(hour: Int) -> Bool {
        // Вычисляем скорректированный час с учетом zeroPosition
        let hourShift = Int(zeroPosition / 15.0)
        let adjustedHour = (hour - hourShift + 24) % 24
        return adjustedHour % numberInterval == 0
    }

    // MARK: - Вспомогательные методы из ViewModel
    // private var tasksForSelectedDate: [TaskOnRing] { ... } - удалено, используем viewModel.tasksForSelectedDate
    // private func timeForLocation(_ location: CGPoint) -> Date { ... } - удалено, используем viewModel.timeForLocation
}
