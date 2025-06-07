import SwiftUI

struct ThemeModeToggle: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isAnimating = false
    
    var body: some View {
        CustomThreeWayToggle(
            currentMode: themeManager.currentThemeMode,
            onModeChange: { newMode in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    themeManager.setThemeMode(newMode)
                    isAnimating.toggle()
                }
            }
        )
        .padding(.horizontal)
    }
}

struct CustomThreeWayToggle: View {
    let currentMode: ThemeMode
    let onModeChange: (ThemeMode) -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    // Вычисляемые свойства для адаптации под тему
    private var backgroundGradient: LinearGradient {
        if themeManager.isDarkMode {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.22, green: 0.22, blue: 0.22),
                    Color(red: 0.18, green: 0.18, blue: 0.18)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.98, green: 0.98, blue: 0.98),
                    Color(red: 0.95, green: 0.95, blue: 0.95)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var borderGradient: LinearGradient {
        if themeManager.isDarkMode {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.gray.opacity(0.6),
                    Color.gray.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.8),
                    Color.gray.opacity(0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var shadowColor: Color {
        themeManager.isDarkMode ? .black.opacity(0.4) : .gray.opacity(0.2)
    }
    
    private var inactiveIconColor: Color {
        themeManager.isDarkMode ? .gray.opacity(0.5) : .gray.opacity(0.6)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Левая секция - Light mode
            Button(action: {
                if currentMode != .light {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onModeChange(.light)
                    }
                }
            }) {
                ZStack {
                    if currentMode == .light {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.yellow.opacity(0.8),
                                        Color.orange.opacity(0.6)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                            .shadow(color: .yellow.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                    
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(currentMode == .light ? .white : inactiveIconColor)
                        .font(.system(size: 16, weight: .medium))
                }
                .frame(width: 40, height: 40)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Средняя секция - Auto mode
            Button(action: {
                if currentMode != .auto {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onModeChange(.auto)
                    }
                }
            }) {
                ZStack {
                    if currentMode == .auto {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue.opacity(0.8),
                                        Color.cyan.opacity(0.6)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                            .shadow(color: .blue.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                    
                    Image(systemName: "gear")
                        .foregroundColor(currentMode == .auto ? .white : inactiveIconColor)
                        .font(.system(size: 16, weight: .medium))
                }
                .frame(width: 40, height: 40)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Правая секция - Dark mode
            Button(action: {
                if currentMode != .dark {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onModeChange(.dark)
                    }
                }
            }) {
                ZStack {
                    if currentMode == .dark {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.indigo.opacity(0.9),
                                        Color.purple.opacity(0.7)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                            .shadow(color: .indigo.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                    
                    Image(systemName: "moon.fill")
                        .foregroundColor(currentMode == .dark ? .white : inactiveIconColor)
                        .font(.system(size: 16, weight: .medium))
                }
                .frame(width: 40, height: 40)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(backgroundGradient)
                .shadow(color: shadowColor, radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .strokeBorder(borderGradient, lineWidth: 1)
        )
    }
}
