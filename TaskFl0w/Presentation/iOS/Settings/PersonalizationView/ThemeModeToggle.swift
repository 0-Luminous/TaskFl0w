import SwiftUI

struct ThemeModeToggle: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isAnimating = false
    
    var body: some View {
        Toggle("", isOn: Binding(
            get: { themeManager.isDarkMode },
            set: { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    themeManager.toggleTheme()
                    isAnimating.toggle()
                }
            }
        ))
        .toggleStyle(CustomToggleStyle())
        .padding(.horizontal)
    }
}

struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            RoundedRectangle(cornerRadius: 25)
                .fill(configuration.isOn ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 0.9, green: 0.9, blue: 0.9))
                .frame(width: 90, height: 40)
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    configuration.isOn ? Color(red: 0.1, green: 0.1, blue: 0.2) : Color(red: 0.8, green: 0.8, blue: 0.8),
                                    configuration.isOn ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color(red: 0.9, green: 0.9, blue: 0.9)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            configuration.isOn ? 
                                                Color.gray.opacity(0.3) :
                                                Color.gray.opacity(0.3),
                                            configuration.isOn ?
                                                Color(red: 0.2, green: 0.2, blue: 0.4, opacity: 0.4) :
                                                Color(red: 0.7, green: 0.7, blue: 0.9, opacity: 0.4)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: configuration.isOn ? "moon.fill" : "sun.max.fill")
                                .foregroundColor(configuration.isOn ? .white : .red1)
                                .font(.system(size: 16))
                        )
                        .offset(x: configuration.isOn ? 25 : -25)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.5, green: 0.5, blue: 0.5, opacity: 0.5),
                                    Color(red: 0.3, green: 0.3, blue: 0.3, opacity: 0.3),
                                    Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: configuration.isOn ? 
                    Color.black.opacity(0.25) : 
                    Color.gray.opacity(0.15), 
                    radius: 3, x: 0, y: 1)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        configuration.$isOn.wrappedValue.toggle()
                    }
                }
        }
    }
}
