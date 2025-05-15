import SwiftUI

// Модификатор для стандартных кнопок
struct ButtonModifier: ViewModifier {
    let isSelected: Bool
    let isDisabled: Bool
    @ObservedObject private var themeManager = ThemeManager.shared
    init(isSelected: Bool = false, isDisabled: Bool = false) {
        self.isSelected = isSelected
        self.isDisabled = isDisabled
    }

    func body(content: Content) -> some View {
        content
            .font(.caption)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .foregroundColor(
                isSelected
                    ? (themeManager.isDarkMode ? .yellow : .red1)
                    : (themeManager.isDarkMode ? .white : .black)
            )
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(
                        themeManager.isDarkMode
                            ? Color(red: 0.184, green: 0.184, blue: 0.184)
                            : Color(red: 0.95, green: 0.95, blue: 0.95)
                                .opacity(isDisabled ? 0.5 : 1)
                    )
                    .shadow(
                        color: isSelected
                            ? (themeManager.isDarkMode
                                ? Color.yellow.opacity(0.2) : Color.red1.opacity(0.2))
                            : .black.opacity(0.5),
                        radius: 3,
                        x: 0,
                        y: isSelected ? 0 : 2
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(isDisabled ? 0.3 : 0.7),
                                Color.gray.opacity(isDisabled ? 0.1 : 0.3),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isDisabled ? 0.5 : 1.0
                    )
            )

            .opacity(isDisabled ? 0.6 : 1)
    }
}

// Модификатор для декоративных кнопок панели инструментов
struct DockButtonModifier: ViewModifier {
    let isSelected: Bool
    @ObservedObject private var themeManager = ThemeManager.shared

    func body(content: Content) -> some View {
        content
            .font(.system(size: 20))
            .foregroundColor(
                isSelected
                    ? (themeManager.isDarkMode ? .yellow : .red1)
                    : (themeManager.isDarkMode ? .white : .black)
            )
            .padding(6)
            .background(
                Circle()
                    .fill(
                        themeManager.isDarkMode
                            ? Color(red: 0.184, green: 0.184, blue: 0.184)
                            : Color(red: 0.95, green: 0.95, blue: 0.95)
                    )
                    .shadow(
                        color: themeManager.isDarkMode ? .black.opacity(0.5) : .black.opacity(0.5),
                        radius: 3, x: 0, y: 2)
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.7), Color.gray.opacity(0.3),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
    }
}

// Модификатор для кнопок навигации
struct NavigationButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .foregroundColor(.white)
            .background(
                Capsule()
                    .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.7),
                                Color.gray.opacity(0.3),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
    }
}

// Расширения для применения модификаторов
extension View {
    func buttonStyle(isSelected: Bool = false, isDisabled: Bool = false) -> some View {
        self.modifier(ButtonModifier(isSelected: isSelected, isDisabled: isDisabled))
    }

    func dockButtonStyle(isSelected: Bool = false) -> some View {
        self.modifier(DockButtonModifier(isSelected: isSelected))
    }

    func navigationButtonStyle() -> some View {
        self.modifier(NavigationButtonModifier())
    }
}
