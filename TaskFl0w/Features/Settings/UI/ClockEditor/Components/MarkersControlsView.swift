import SwiftUI

struct MarkersControlsView: View {
    @ObservedObject var viewModel: ClockViewModel
    @ObservedObject var markersViewModel: ClockMarkersViewModel
    @Binding var showMarkers: Bool
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedStyle: MarkerStyle = .lines
    @State private var showStylePicker: Bool = false // Для показа/скрытия выбора стиля

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
                .disabled(!markersViewModel.showMarkers && viewModel.themeConfig.clockStyle == "Цифровой")
                .opacity(
                    !markersViewModel.showMarkers && viewModel.themeConfig.clockStyle == "Цифровой" ? 0.5 : 1)
            }
            .padding(.bottom, 8)
            
            // После первой кнопки, которая включает/выключает маркеры, добавляем:
            if markersViewModel.showMarkers {
                HStack(spacing: 10) {
                    Button(action: {
                        markersViewModel.showIntermediateMarkers.toggle()
                        viewModel.themeConfig.showIntermediateMarkers = markersViewModel.showIntermediateMarkers
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
                
                // Кнопка выбора стиля маркеров (заменяет галерею стилей)
                VStack(spacing: 8) {
                    Button(action: {
                        withAnimation {
                            showStylePicker.toggle()
                        }
                    }) {
                        HStack {
                            // Превью текущего стиля
                            stylePreviewView(for: markersViewModel.markerStyle)
                                .frame(width: 50, height: 30)
                                .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                                .padding(.leading, 8)
                            
                            Text("Стиль маркеров: \(markersViewModel.markerStyleNames[markersViewModel.markerStyle] ?? "")")
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                            
                            Spacer()
                            
                            Image(systemName: showStylePicker ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                                .padding(.trailing, 10)
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    themeManager.isDarkMode
                                        ? Color(red: 0.184, green: 0.184, blue: 0.184)
                                        : Color(red: 0.95, green: 0.95, blue: 0.95)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
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
                    
                    // Выпадающее меню стилей
                    if showStylePicker {
                        VStack(spacing: 2) {
                            ForEach([MarkerStyle.lines, .dots, .standard, .classicWatch, .thinUniform, .hourAccent, .uniformDense], id: \.self) { style in
                                Button(action: {
                                    markersViewModel.markerStyle = style
                                    viewModel.themeConfig.markerStyle = style
                                    selectedStyle = style
                                    withAnimation {
                                        showStylePicker = false
                                    }
                                }) {
                                    HStack {
                                        stylePreviewView(for: style)
                                            .frame(width: 50, height: 30)
                                            .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                                            .padding(.leading, 8)
                                        
                                        Text(markersViewModel.markerStyleNames[style] ?? "")
                                            .font(.caption)
                                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                                        
                                        Spacer()
                                        
                                        if style == markersViewModel.markerStyle {
                                            Image(systemName: "checkmark")
                                                .font(.caption)
                                                .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                                                .padding(.trailing, 10)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(
                                                style == markersViewModel.markerStyle
                                                ? (themeManager.isDarkMode ? Color.yellow.opacity(0.15) : Color.red1.opacity(0.15))
                                                : Color.clear
                                            )
                                    )
                                    .padding(.horizontal, 4)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    themeManager.isDarkMode
                                        ? Color(red: 0.22, green: 0.22, blue: 0.22)
                                        : Color(red: 0.92, green: 0.92, blue: 0.92)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.bottom, 8)

                // Вторая строка с управлением толщиной
                HStack(spacing: 10) {
                    // Кнопка уменьшения толщины
                    Button(action: {
                        if markersViewModel.markersWidth > 1.0 {
                            markersViewModel.markersWidth -= 0.5
                            viewModel.themeConfig.markersWidth = markersViewModel.markersWidth
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
                            viewModel.themeConfig.markersWidth = markersViewModel.markersWidth
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
                // Text(
                //     "Толщина маркеров влияет на визуальное отображение циферблата. Более тонкие маркеры создают минималистичный вид, а более толстые обеспечивают лучшую видимость."
                // )
                // .font(.caption)
                // .foregroundColor(.gray)
                // .frame(maxWidth: .infinity, alignment: .leading)
                // .padding(.top, 4)
            }

            // После кнопки для промежуточных маркеров:
            // if markersViewModel.showMarkers && markersViewModel.showIntermediateMarkers {
            //     Text("Промежуточные маркеры добавляют более детальную шкалу между часовыми отметками, делая циферблат более точным.")
            //         .font(.caption)
            //         .foregroundColor(.gray)
            //         .frame(maxWidth: .infinity, alignment: .leading)
            //         .padding(.top, 4)
            //         .padding(.bottom, 8)
            // }
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
        case .standard:
            HStack(spacing: 4) {
                Rectangle().frame(width: 2, height: 12)
                Rectangle().frame(width: 2, height: 16)
                Rectangle().frame(width: 2, height: 12)
                Rectangle().frame(width: 2, height: 16)
            }
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
