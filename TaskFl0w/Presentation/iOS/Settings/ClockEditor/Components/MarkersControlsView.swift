import SwiftUI

struct MarkersControlsView: View {
    @ObservedObject var viewModel: ClockViewModel
    @ObservedObject var markersViewModel: ClockMarkersViewModel
    @Binding var showMarkers: Bool
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedStyle: MarkerStyle = .lines

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
            
            // После первой кнопки, которая включает/выключает маркеры, добавляем:
            if markersViewModel.showMarkers {
                HStack(spacing: 10) {
                    Button(action: {
                        markersViewModel.showIntermediateMarkers.toggle()
                        viewModel.showIntermediateMarkers = markersViewModel.showIntermediateMarkers
                    }) {
                        HStack {
                            Text(markersViewModel.showIntermediateMarkers ? "Скрыть промежуточные" : "Показать промежуточные")
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                            Image(systemName: markersViewModel.showIntermediateMarkers ? "chevron.up.chevron.down" : "chevron.compact.up.chevron.compact.down")
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
                                    color: markersViewModel.showIntermediateMarkers
                                        ? Color.black.opacity(0.5) : Color.yellow.opacity(0.2),
                                    radius: markersViewModel.showIntermediateMarkers ? 3 : 5,
                                    x: 0,
                                    y: markersViewModel.showIntermediateMarkers ? 2 : 0
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
                }
                .padding(.bottom, 8)
            }

            // Выбор стиля маркеров
            if markersViewModel.showMarkers {
                VStack(spacing: 8) {
                    Text("Стиль маркеров")
                        .font(.caption)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Первый ряд стилей - стандартные
                    HStack(spacing: 10) {
                        ForEach([MarkerStyle.lines, .dots, .numbers], id: \.self) { style in
                            styleButton(for: style)
                        }
                    }
                    
                    // Второй ряд стилей - новые, как на картинке
                    HStack(spacing: 10) {
                        ForEach([MarkerStyle.classicWatch, .thinUniform, .hourAccent, .uniformDense], id: \.self) { style in
                            styleButton(for: style)
                        }
                    }
                }
                .padding(.bottom, 8)
            }

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

            // После кнопки для промежуточных маркеров:
            if markersViewModel.showMarkers && markersViewModel.showIntermediateMarkers {
                Text("Промежуточные маркеры добавляют более детальную шкалу между часовыми отметками, делая циферблат более точным.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
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
        .onAppear {
            selectedStyle = markersViewModel.markerStyle
        }
    }
    
    @ViewBuilder
    private func styleButton(for style: MarkerStyle) -> some View {
        Button(action: {
            markersViewModel.markerStyle = style
            viewModel.markerStyle = style
            selectedStyle = style
        }) {
            VStack {
                stylePreviewView(for: style)
                    .frame(width: 40, height: 40)
                    .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                
                Text(markersViewModel.markerStyleNames[style] ?? "")
                    .font(.caption2)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedStyle == style 
                         ? (themeManager.isDarkMode ? Color.yellow.opacity(0.3) : Color.red1.opacity(0.3))
                         : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selectedStyle == style 
                            ? (themeManager.isDarkMode ? Color.yellow : Color.red1)
                            : Color.gray.opacity(0.3), 
                            lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func stylePreviewView(for style: MarkerStyle) -> some View {
        switch style {
        case .lines:
            HStack(spacing: 4) {
                Rectangle().frame(width: 2, height: 14)
                Rectangle().frame(width: 2, height: 10)
                Rectangle().frame(width: 2, height: 14)
            }
        case .dots:
            HStack(spacing: 4) {
                Circle().frame(width: 6, height: 6)
                Circle().frame(width: 4, height: 4)
                Circle().frame(width: 6, height: 6)
            }
        case .numbers:
            Text("3 6 9")
                .font(.system(size: 10))
        case .classicWatch:
            HStack(spacing: 4) {
                Rectangle().frame(width: 3, height: 16)
                Rectangle().frame(width: 1.5, height: 8)
                Rectangle().frame(width: 1.5, height: 8)
                Rectangle().frame(width: 2, height: 12)
            }
        case .thinUniform:
            HStack(spacing: 3) {
                Rectangle().frame(width: 1, height: 8)
                Rectangle().frame(width: 1, height: 8)
                Rectangle().frame(width: 1, height: 8)
                Rectangle().frame(width: 1, height: 8)
            }
        case .hourAccent:
            HStack(spacing: 3) {
                Rectangle().frame(width: 1.5, height: 14)
                Rectangle().opacity(0.3).frame(width: 0.8, height: 6)
                Rectangle().opacity(0.3).frame(width: 0.8, height: 6)
                Rectangle().opacity(0.7).frame(width: 1, height: 10)
            }
        case .uniformDense:
            HStack(spacing: 2) {
                Rectangle().frame(width: 2, height: 12)
                Rectangle().frame(width: 2, height: 8)
                Rectangle().frame(width: 2, height: 8)
                Rectangle().frame(width: 2, height: 8)
                Rectangle().frame(width: 2, height: 8)
            }
        }
    }
}
