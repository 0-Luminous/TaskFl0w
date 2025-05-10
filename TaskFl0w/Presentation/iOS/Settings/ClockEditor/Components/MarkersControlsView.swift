import SwiftUI

struct MarkersControlsView: View {
    @ObservedObject var viewModel: ClockViewModel
    @ObservedObject var markersViewModel: ClockMarkersViewModel
    @Binding var showMarkers: Bool
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 16) {
            Text("Настройки маркеров")
                .font(.headline)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Первая строка с переключателем отображения маркеров
            HStack(spacing: 10) {
                Button(action: {
                    markersViewModel.showMarkers.toggle()
                    showMarkers = markersViewModel.showMarkers
                }) {
                    HStack {
                        Text(markersViewModel.showMarkers ? "Скрыть маркеры" : "Показать маркеры")
                            .font(.caption)
                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        Image(systemName: markersViewModel.showMarkers ? "eye.slash" : "eye")
                            .font(.caption)
                            .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(
                                themeManager.isDarkMode
                                    ? Color(red: 0.184, green: 0.184, blue: 0.184)
                                    : Color(red: 0.95, green: 0.95, blue: 0.95)
                            )
                            .shadow(
                                color: markersViewModel.showMarkers
                                    ? Color.black.opacity(0.5) : Color.yellow.opacity(0.2),
                                radius: markersViewModel.showMarkers ? 3 : 5,
                                x: 0,
                                y: markersViewModel.showMarkers ? 2 : 0
                            )
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
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!markersViewModel.showMarkers && viewModel.clockStyle == "Цифровой")
                .opacity(
                    !markersViewModel.showMarkers && viewModel.clockStyle == "Цифровой" ? 0.5 : 1)
            }
            .padding(.bottom, 8)

            // Вторая строка с управлением толщиной
            if markersViewModel.showMarkers {
                HStack(spacing: 10) {
                    // Кнопка уменьшения толщины
                    Button(action: {
                        if markersViewModel.markersWidth > 1.0 {
                            markersViewModel.markersWidth -= 0.5
                            viewModel.markersWidth = markersViewModel.markersWidth
                        }
                    }) {
                        HStack {
                            Text("Тоньше")
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                            Image(systemName: "minus")
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                        }
                        .buttonStyle()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(markersViewModel.markersWidth <= 1.0)
                    .opacity(markersViewModel.markersWidth <= 1.0 ? 0.5 : 1)

                    // Значение толщины
                    Text("\(markersViewModel.markersWidth, specifier: "%.1f")")
                        .font(.system(size: 18))
                        .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                        .frame(width: 40)

                    // Кнопка увеличения толщины
                    Button(action: {
                        if markersViewModel.markersWidth < 8.0 {
                            markersViewModel.markersWidth += 0.5
                            viewModel.markersWidth = markersViewModel.markersWidth
                        }
                    }) {
                        HStack {
                            Text("Толще")
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                            Image(systemName: "plus")
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                        }
                        .buttonStyle()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(markersViewModel.markersWidth >= 8.0)
                    .opacity(markersViewModel.markersWidth >= 8.0 ? 0.5 : 1)
                }
                .padding(.bottom, 8)

                // Дополнительная информация о маркерах
                Text(
                    "Толщина маркеров влияет на визуальное отображение циферблата. Более тонкие маркеры создают минималистичный вид, а более толстые обеспечивают лучшую видимость."
                )
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    themeManager.isDarkMode
                        ? Color(red: 0.18, green: 0.18, blue: 0.18).opacity(0.98)
                        : Color(red: 0.95, green: 0.95, blue: 0.95).opacity(0.98)
                )
                .shadow(radius: 8)
        )
        .padding(.horizontal, 24)
    }
}
