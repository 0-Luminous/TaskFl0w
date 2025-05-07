import SwiftUI

struct ClockMarker: View {
    let hour: Int
    let style: MarkerStyle
    @ObservedObject var viewModel: ClockMarkersViewModel
    let MarkersColor: Color
    let zeroPosition: Double
    let showNumbers: Bool

    // Вычисляемое свойство для получения скорректированного часа с учетом zeroPosition
    private var adjustedHour: Int {
        // Вычисляем сдвиг в часах на основе zeroPosition
        // zeroPosition в градусах, переводим в часы (15 градусов = 1 час)
        let hourShift = Int(zeroPosition / 15.0)

        // Сдвигаем час с учетом hourShift и обеспечиваем корректность (0-23)
        let adjustedHour = (hour - hourShift + 24) % 24

        return adjustedHour
    }
    
    // Проверяем, нужно ли отображать число для данного часа
    private var shouldShowNumber: Bool {
        // Если интервал 1 - показываем все числа
        // Если 2 - каждое второе (четные)
        // Если 3 - каждое третье (0, 3, 6, 9, 12, 15, 18, 21)
        // Если 6 - каждое шестое (0, 6, 12, 18)
        return adjustedHour % viewModel.numberInterval == 0
    }
    
    // Получаем высоту маркера в зависимости от часа и интервала
    private var dynamicMarkerHeight: CGFloat {
        if viewModel.showHourNumbers {
            // Если этот час должен иметь цифру, делаем маркер выше
            if shouldShowNumber && viewModel.numberInterval > 1 {
                return viewModel.markerHeight(for: hour) * 1.0
            }
        }
        return viewModel.markerHeight(for: hour)
    }
    
    // Вычислить позицию маркера с учетом настроек отступа
    private var markerPosition: CGFloat {
        viewModel.markerOffset()
    }

    var body: some View {
        // Только маркер, без цифр
        markerView
            .offset(y: markerPosition)
    }
    
    // Отображение маркера в зависимости от стиля
    private var markerView: some View {
        Group {
            switch style {
            case .numbers:
                Rectangle()
                    .fill(MarkersColor)
                    .frame(width: viewModel.markersWidth, height: shouldShowNumber && viewModel.numberInterval > 1 ? 16 : 12)
                    
            case .lines:
            Rectangle()
                    .fill(MarkersColor)
                    .frame(width: viewModel.markersWidth, height: dynamicMarkerHeight)
                    
            case .dots:
                Circle()
                .fill(MarkersColor)
                .frame(
                        width: shouldShowNumber && viewModel.numberInterval > 1 ? viewModel.markerWidth(for: hour) * 1.5 : viewModel.markerWidth(for: hour),
                        height: shouldShowNumber && viewModel.numberInterval > 1 ? viewModel.markerWidth(for: hour) * 1.5 : viewModel.markerWidth(for: hour))
            }
        }
    }
}
