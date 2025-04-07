import SwiftUI
import UIKit

// Импортируем необходимые типы
import TaskFl0w

struct ClockMarker: View {
    let hour: Int
    let style: MarkerStyle
    @ObservedObject var viewModel: ClockMarkersViewModel
    let MarkersColor: Color
    let zeroPosition: Double

    // Вычисляемое свойство для получения скорректированного часа с учетом zeroPosition
    private var adjustedHour: Int {
        // Вычисляем сдвиг в часах на основе zeroPosition
        // zeroPosition в градусах, переводим в часы (15 градусов = 1 час)
        let hourShift = Int(zeroPosition / 15.0)

        // Сдвигаем час с учетом hourShift и обеспечиваем корректность (0-23)
        let adjustedHour = (hour - hourShift + 24) % 24

        return adjustedHour
    }

    var body: some View {
        VStack(spacing: 0) {
            switch style {
            case .numbers:
                Rectangle()
                    .fill(MarkersColor)
                    .frame(width: viewModel.markersWidth, height: 12)
                if viewModel.showHourNumbers {
                    Text("\(adjustedHour)")
                        .font(.system(size: viewModel.numbersSize))
                        .foregroundColor(MarkersColor)
                        .rotationEffect(.degrees(-Double(hour) * (360.0 / 24.0) - zeroPosition))
                        .offset(y: 5)
                }

            case .lines:
                Rectangle()
                    .fill(MarkersColor)
                    .frame(width: viewModel.markersWidth, height: viewModel.markerHeight(for: hour))

            case .dots:
                Circle()
                    .fill(MarkersColor)
                    .frame(
                        width: viewModel.markerWidth(for: hour),
                        height: viewModel.markerWidth(for: hour))
            }
        }
        .offset(y: viewModel.markerOffset())
    }
}
