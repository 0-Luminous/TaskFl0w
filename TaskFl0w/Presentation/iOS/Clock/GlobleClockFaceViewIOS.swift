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

    @Binding var draggedCategory: TaskCategoryModel?
    let clockFaceColor: Color
    let zeroPosition: Double

    // Добавляем новый параметр
    var isNavigationOverlayVisible: Bool = false

    @Environment(\.colorScheme) var colorScheme
    @AppStorage("clockStyle") private var clockStyle: ClockStyle = .classic
    @AppStorage("markersOffset") private var markersOffset: Double = 40.0

    // Локальные состояния убраны и перенесены в ViewModel
    // Используем состояния из ViewModel через viewModel

    var body: some View {
        ZStack {
            Circle()
                .fill(clockFaceColor)
                .stroke(Color.gray, lineWidth: 2)

            // Маркеры часов (24 шт.)
            ForEach(0..<24) { hour in
                let angle = Double(hour) * (360.0 / 24.0)
                ClockMarker(
                    hour: hour,
                    style: clockStyle.markerStyle,
                    viewModel: markersViewModel,
                    zeroPosition: zeroPosition
                )
                .rotationEffect(.degrees(angle + zeroPosition))
                .frame(
                    width: UIScreen.main.bounds.width * 0.7,
                    height: UIScreen.main.bounds.width * 0.7)
            }

            TaskArcsViewIOS(
                tasks: viewModel.tasksForSelectedDate(tasks),
                viewModel: viewModel
            )

            ClockHandViewIOS(currentDate: viewModel.selectedDate)
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
        .onAppear {
            markersViewModel.zeroPosition = zeroPosition
        }
        .onChange(of: zeroPosition) { oldValue, newValue in
            markersViewModel.zeroPosition = newValue
        }
    }

    // MARK: - Вспомогательные методы из ViewModel
    // private var tasksForSelectedDate: [TaskOnRing] { ... } - удалено, используем viewModel.tasksForSelectedDate
    // private func timeForLocation(_ location: CGPoint) -> Date { ... } - удалено, используем viewModel.timeForLocation
}
