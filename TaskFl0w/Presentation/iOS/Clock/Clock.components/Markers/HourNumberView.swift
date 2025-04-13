import SwiftUI

/// Компонент для отображения числовых значений часов на циферблате
struct HourNumberView: View {
    let hour: Int
    @ObservedObject var viewModel: ClockMarkersViewModel
    let color: Color
    let zeroPosition: Double
    
    // Вычисляемое свойство для получения скорректированного часа с учетом zeroPosition
    private var adjustedHour: Int {
        // Проверяем, что zeroPosition - корректное число, иначе используем 0
        let sanitizedZeroPosition = zeroPosition.isNaN ? 0.0 : zeroPosition
        
        // Вычисляем сдвиг в часах на основе zeroPosition
        // zeroPosition в градусах, переводим в часы (15 градусов = 1 час)
        let hourShift = Int(sanitizedZeroPosition / 15.0)

        // Сдвигаем час с учетом hourShift и обеспечиваем корректность (0-23)
        let adjustedHour = (hour - hourShift + 24) % 24

        return adjustedHour
    }
    
    private var rotationAngle: Double {
        // Проверка на NaN для безопасного вычисления
        let safeHour = Double(hour).isNaN ? 0.0 : Double(hour)
        return -safeHour * (360.0 / 24.0)
    }
    
    private var numberOffset: CGFloat {
        // Используем безопасное значение для смещения
        let offset = viewModel.numberOffset()
        return offset.isNaN ? 0.0 : offset
    }
    
    var body: some View {
        Text("\(adjustedHour)")
            .font(.system(size: viewModel.numbersSize.isNaN ? 16.0 : viewModel.numbersSize))
            .foregroundColor(color)
            // Удаляем применение zeroPosition в rotationEffect,
            // так как цифра уже скорректирована в adjustedHour
            // и весь циферблат уже поворачивается с учетом zeroPosition
            .rotationEffect(.degrees(rotationAngle))
            .offset(y: numberOffset)
            // Добавляем дополнительный модификатор для принудительного обновления при изменении размера
            .id("hour-\(hour)-size-\(Int(viewModel.numbersSize))-zero-\(Int(zeroPosition))")
    }
} 