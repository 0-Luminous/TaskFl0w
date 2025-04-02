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
                let angle = Double(hour) * (360.0 / 24.0) + zeroPosition
                ClockMarker(hour: hour, style: clockStyle.markerStyle, viewModel: markersViewModel)
                    .rotationEffect(.degrees(angle))
                    .frame(
                        width: UIScreen.main.bounds.width * 0.7,
                        height: UIScreen.main.bounds.width * 0.7)
            }

            TaskArcsViewIOS(
                tasks: tasksForSelectedDate,
                viewModel: viewModel
            )

            ClockHandViewIOS(currentDate: viewModel.currentDate)
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
        .animation(.spring(), value: tasksForSelectedDate)
    }

    // MARK: - Вспомогательные

    private var tasksForSelectedDate: [TaskOnRing] {
        tasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: viewModel.selectedDate)
        }
    }

    private func timeForLocation(_ location: CGPoint) -> Date {
        let center = CGPoint(
            x: UIScreen.main.bounds.width * 0.35,
            y: UIScreen.main.bounds.width * 0.35)
        let vector = CGVector(dx: location.x - center.x, dy: location.y - center.y)

        let angle = atan2(vector.dy, vector.dx)

        // Переводим в градусы и учитываем zeroPosition
        var degrees = angle * 180 / .pi
        degrees = (degrees - 90 - zeroPosition + 360).truncatingRemainder(dividingBy: 360)

        // 24 часа = 360 градусов => 1 час = 15 градусов
        let hours = degrees / 15
        let hourComponent = Int(hours)
        let minuteComponent = Int((hours - Double(hourComponent)) * 60)

        // Используем компоненты из selectedDate вместо currentDate
        var components = Calendar.current.dateComponents(
            [.year, .month, .day], from: viewModel.selectedDate)
        components.hour = hourComponent
        components.minute = minuteComponent
        components.timeZone = TimeZone.current

        return Calendar.current.date(from: components) ?? viewModel.selectedDate
    }
}
