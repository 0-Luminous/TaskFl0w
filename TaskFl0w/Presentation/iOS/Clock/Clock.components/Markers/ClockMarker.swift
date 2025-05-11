import SwiftUI

struct ClockMarker: View {
    let hour: Int
    var minuteIndex: Int? = nil // Индекс минутного маркера (null для часового)
    let style: MarkerStyle
    @ObservedObject var viewModel: ClockMarkersViewModel
    let MarkersColor: Color
    let zeroPosition: Double
    let showNumbers: Bool
    var isMainMarker: Bool = true // True для часовых, false для минутных

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
                if isMainMarker {
                    Rectangle()
                        .fill(MarkersColor)
                        .frame(width: viewModel.markersWidth, height: shouldShowNumber && viewModel.numberInterval > 1 ? 16 : 12)
                } else {
                    // Минутные маркеры для стиля с цифрами
                    Rectangle()
                        .fill(MarkersColor.opacity(0.6))
                        .frame(width: max(1.0, viewModel.markersWidth * 0.5), height: 8)
                }
                    
            case .lines:
                if isMainMarker {
                    Rectangle()
                        .fill(MarkersColor)
                        .frame(width: viewModel.markersWidth, height: dynamicMarkerHeight)
                } else {
                    // Минутные маркеры для стиля с линиями
                    Rectangle()
                        .fill(MarkersColor.opacity(0.7))
                        .frame(width: max(1.0, viewModel.markersWidth * 0.7), height: 8)
                }
                    
            case .dots:
                if isMainMarker {
                    Circle()
                        .fill(MarkersColor)
                        .frame(
                            width: shouldShowNumber && viewModel.numberInterval > 1 ? viewModel.markerWidth(for: hour) * 1.5 : viewModel.markerWidth(for: hour),
                            height: shouldShowNumber && viewModel.numberInterval > 1 ? viewModel.markerWidth(for: hour) * 1.5 : viewModel.markerWidth(for: hour))
                } else {
                    // Минутные маркеры для стиля с точками
                    Circle()
                        .fill(MarkersColor.opacity(0.6))
                        .frame(width: viewModel.markerWidth(for: hour) * 0.6, height: viewModel.markerWidth(for: hour) * 0.6)
                }
            
            // Классические часовые маркеры (верхний левый)
            case .classicWatch:
                if isMainMarker {
                    Rectangle()
                        .fill(MarkersColor)
                        .frame(
                            width: hour % 6 == 0 ? viewModel.markersWidth * 1.5 : viewModel.markersWidth * 0.8, 
                            height: hour % 6 == 0 ? 18 : (hour % 3 == 0 ? 14 : 8)
                        )
                } else {
                    // Минутные маркеры для классического стиля
                    Rectangle()
                        .fill(MarkersColor.opacity(0.5))
                        .frame(width: viewModel.markersWidth * 0.5, height: 5)
                }
            
            // Тонкие равномерные линии (верхний правый)
            case .thinUniform:
                if isMainMarker {
                    Rectangle()
                        .fill(MarkersColor)
                        .frame(
                            width: max(1.0, viewModel.markersWidth * 0.5),
                            height: hour % 6 == 0 ? 12 : 8
                        )
                } else {
                    // Минутные маркеры для тонкого стиля
                    Rectangle()
                        .fill(MarkersColor.opacity(0.7))
                        .frame(width: max(0.5, viewModel.markersWidth * 0.3), height: 6)
                }
            
            // Акцент только на часовых маркерах, очень тонкие линии (нижний левый)
            case .hourAccent:
                if isMainMarker {
                    if hour % 3 == 0 {
                        Rectangle()
                            .fill(MarkersColor.opacity(hour % 6 == 0 ? 1.0 : 0.7))
                            .frame(
                                width: max(1.0, viewModel.markersWidth * 0.4),
                                height: hour % 6 == 0 ? 14 : 10
                            )
                    } else {
                        Rectangle()
                            .fill(MarkersColor.opacity(0.3))
                            .frame(
                                width: max(1.0, viewModel.markersWidth * 0.3),
                                height: 6
                            )
                    }
                } else {
                    // Минутные маркеры для стиля с акцентом на часах
                    Rectangle()
                        .fill(MarkersColor.opacity(0.2))
                        .frame(width: max(0.5, viewModel.markersWidth * 0.2), height: 4)
                }
            
            // Плотные равномерные линии (нижний правый)
            case .uniformDense:
                if isMainMarker {
                    Rectangle()
                        .fill(MarkersColor)
                        .frame(
                            width: viewModel.markersWidth * 0.9,
                            height: hour % 6 == 0 ? 12 : 8
                        )
                } else {
                    // Минутные маркеры для плотного стиля
                    Rectangle()
                        .fill(MarkersColor.opacity(0.7))
                        .frame(width: viewModel.markersWidth * 0.6, height: 7)
                }
            }
        }
    }
}
