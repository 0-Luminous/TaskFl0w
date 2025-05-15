import SwiftUI

// Вспомогательные функции для работы с цветами
struct ColorUtils {
    
    // Получает цвет на определенной позиции слайдера с уменьшенным диапазоном
    static func getColorAt(position: CGFloat, baseColor: Color) -> Color {
        // Уменьшаем диапазон изменения яркости (1.3-0.7)
        // Где 0 на слайдере = яркость 1.3 (умеренно светлый)
        // А 1 на слайдере = яркость 0.7 (умеренно темный)
        let brightnessFactor = 1.3 - (position * 0.6)
        
        if position < 0.5 {
            // Левая сторона, светлее базового цвета
            return brightenColor(baseColor, factor: brightnessFactor)
        } else if position > 0.5 {
            // Правая сторона, темнее базового цвета
            return darkenColor(baseColor, factor: brightnessFactor)
        } else {
            // Центр, базовый цвет
            return baseColor
        }
    }
    
    // Получает базовый цвет для цвета
    static func getBaseColor(forColor color: Color) -> Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
    }
    
    // Получает яркость цвета
    static func getBrightness(of color: Color) -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (red * 0.299 + green * 0.587 + blue * 0.114)
    }
    
    // Увеличивает яркость цвета
    static func brightenColor(_ color: Color, factor: CGFloat) -> Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        red = min(max(red * factor, 0), 1)
        green = min(max(green * factor, 0), 1)
        blue = min(max(blue * factor, 0), 1)
        
        return Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
    }
    
    // Уменьшает яркость цвета
    static func darkenColor(_ color: Color, factor: CGFloat) -> Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        red = max(min(red * factor, 1), 0)
        green = max(min(green * factor, 1), 0)
        blue = max(min(blue * factor, 1), 0)
        
        return Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
    }
    
    // Проверяет, является ли цвет светлым
    static func isLightColor(_ color: Color) -> Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Формула для определения яркости
        let brightness = (red * 0.299 + green * 0.587 + blue * 0.114)
        return brightness > 0.7
    }
    
    // Интерполяция между двумя цветами
    static func interpolateColor(from: Color, to: Color, with percentage: Double) -> Color {
        let fromComponents = UIColor(from).cgColor.components ?? [0, 0, 0, 1]
        let toComponents = UIColor(to).cgColor.components ?? [0, 0, 0, 1]
        
        let r = fromComponents[0] + (toComponents[0] - fromComponents[0]) * CGFloat(percentage)
        let g = fromComponents[1] + (toComponents[1] - fromComponents[1]) * CGFloat(percentage)
        let b = fromComponents[2] + (toComponents[2] - fromComponents[2]) * CGFloat(percentage)
        let a = fromComponents[3] + (toComponents[3] - fromComponents[3]) * CGFloat(percentage)
        
        return Color(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }
    
    // Получает цвет из градиента по позиции
    static func colorFromGradient(at percentage: Double) -> Color {
        let colors: [Color] = [.red1, .orange, .yellow, .green0, .Mint1, .Blue1, .Indigo1, .Purple1, .pink]
        let count = Double(colors.count - 1)
        let adjustedPercentage = min(max(percentage, 0), 1) // Обеспечиваем, что процент в пределах 0-1
        
        let index = min(Int(adjustedPercentage * count), colors.count - 2)
        let remainder = (adjustedPercentage * count) - Double(index)
        
        return interpolateColor(from: colors[index], to: colors[index + 1], with: remainder)
    }
    
    // Функция для изменения яркости цвета
    static func adjustColorBrightness(_ color: Color, byPercentage percentage: Double) -> Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Коэффициент, чтобы яркость менялась от 0.5 до 1.5 от текущей
        let brightnessAdjustment = 0.5 + percentage
        
        // Ограничиваем компоненты цвета, чтобы они были в диапазоне 0...1
        red = min(max(red * CGFloat(brightnessAdjustment), 0), 1)
        green = min(max(green * CGFloat(brightnessAdjustment), 0), 1)
        blue = min(max(blue * CGFloat(brightnessAdjustment), 0), 1)
        
        return Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
    }
} 