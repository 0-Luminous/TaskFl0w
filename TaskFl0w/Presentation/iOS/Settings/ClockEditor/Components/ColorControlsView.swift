import SwiftUI

struct ColorControlsView: View {
    @ObservedObject var viewModel: ClockViewModel
    @ObservedObject var markersViewModel: ClockMarkersViewModel
    @ObservedObject var themeManager: ThemeManager
    
    @Binding var lightModeOuterRingColor: String
    @Binding var darkModeOuterRingColor: String
    @Binding var lightModeClockFaceColor: String
    @Binding var darkModeClockFaceColor: String
    @Binding var lightModeMarkersColor: String
    @Binding var darkModeMarkersColor: String
    
    @Binding var showColorPickerSheet: Bool
    @Binding var colorPickerType: String
    @Binding var sliderBrightnessPosition: CGFloat
    @Binding var currentBaseColor: Color
    @Binding var selectedColorType: String
    @Binding var selectedColorHex: String
    @Binding var selectedColorIndex: Int?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Цвета циферблата")
                .font(.headline)
                .foregroundColor(.white)
            
            // Основная секция выбора цвета для циферблата
            VStack(alignment: .leading, spacing: 10) {
                Text("Циферблат")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                // Градиентный слайдер для выбора яркости цвета
                ZStack(alignment: .center) {
                    let currentColor = Color(
                            hex: themeManager.isDarkMode
                            ? darkModeClockFaceColor : lightModeClockFaceColor
                    ) ?? .red
                    
                    // Градиент от светлого к темному
                    LinearGradient(
                        gradient: Gradient(colors: [
                            ColorUtils.brightenColor(currentBaseColor, factor: 1.3),
                            currentBaseColor,
                            ColorUtils.darkenColor(currentBaseColor, factor: 0.7)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 26)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.black.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Ползунок слайдера
                    GeometryReader { geometry in
                        let paddingHorizontal: CGFloat = 30
                        let width = geometry.size.width - paddingHorizontal*2
                        let minX = paddingHorizontal
                        let currentX = minX + (width * sliderBrightnessPosition)
                        
                        Circle()
                            .fill(.white)
                            .frame(width: 36, height: 36)
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                            .overlay(
                                Circle()
                                    .fill(ColorUtils.getColorAt(position: sliderBrightnessPosition, baseColor: currentBaseColor))
                                    .frame(width: 24, height: 24)
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            )
                            .position(x: currentX, y: geometry.size.height / 2)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let maxX = minX + width
                                        let xPosition = min(max(value.location.x, minX), maxX)
                                        sliderBrightnessPosition = (xPosition - minX) / width
                                        
                                        let newColor = ColorUtils.getColorAt(
                                            position: sliderBrightnessPosition, 
                                            baseColor: currentBaseColor
                                        )
                                        let newColorHex = newColor.toHex()
                                        
                                        if themeManager.isDarkMode {
                                            darkModeClockFaceColor = newColorHex
                                        } else {
                                            lightModeClockFaceColor = newColorHex
                                        }
                                    }
                            )
                    }
                }
                .frame(height: 50)
                .padding(.bottom, 10)
                .onAppear {
                    initializeSliderPosition()
                }
                
                // Скролл с готовыми цветами
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        // Базовые нейтральные цвета
                        colorButton(color: Color(red: 0.1, green: 0.1, blue: 0.1), forType: "clockFace", index: -3)
                        colorButton(color: Color(red: 0.2, green: 0.2, blue: 0.2), forType: "clockFace", index: -2)
                        colorButton(color: Color(red: 0.85, green: 0.85, blue: 0.85), forType: "clockFace", index: -1)
                        
                        // Стандартные цвета
                        let standardColors: [Color] = [
                            .Lilac1, .Pink1, .red1, .Peony1, .Rose1, .coral1, .Orange1, .yellow1, .green0, .green1,
                            .Clover1, .Mint1, .Teal1, .Blue1, .LightBlue1, .BlueJay1, .OceanBlue1,
                            .StormBlue1, .Indigo1, .Purple1 
                        ]
                        
                        ForEach(0..<standardColors.count, id: \.self) { index in
                            colorButton(color: standardColors[index], forType: "clockFace", index: index)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
                .frame(height: 50)
            }
            
            // Кнопки для маркеров и внешнего кольца
            HStack(spacing: 10) {
                Button(action: {
                    showColorPickerSheet(for: "markers")
                }) {
                    HStack {
                        Text("Маркеры")
                            .font(.caption)
                            .foregroundColor(.white)
                        Circle()
                            .fill(Color(
                                hex: themeManager.isDarkMode
                                    ? darkModeMarkersColor : lightModeMarkersColor) ?? .gray)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .buttonStyle()
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    showColorPickerSheet(for: "outerRing")
                }) {
                    HStack {
                        Text("Внешнее кольцо")
                            .font(.caption)
                            .foregroundColor(.white)
                        Circle()
                            .fill(Color(
                                hex: themeManager.isDarkMode
                                    ? darkModeOuterRingColor : lightModeOuterRingColor) ?? .gray.opacity(0.3))
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .buttonStyle()
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.18, green: 0.18, blue: 0.18).opacity(0.98))
                .shadow(radius: 8)
        )
        .padding(.horizontal, 24)
    }
    
    func colorButton(color: Color, forType type: String, index: Int? = nil) -> some View {
        // Определяем, выбрана ли эта кнопка
        let isSelected: Bool
        
        if let selectedIndex = selectedColorIndex, selectedIndex == index, selectedColorType == type {
            isSelected = true
        } else {
            let colorHex = color.toHex()
            switch type {
            case "clockFace":
                isSelected = themeManager.isDarkMode ? 
                    (darkModeClockFaceColor == colorHex) : 
                    (lightModeClockFaceColor == colorHex)
            case "markers":
                isSelected = themeManager.isDarkMode ? 
                    (darkModeMarkersColor == colorHex) : 
                    (lightModeMarkersColor == colorHex)
            case "outerRing":
                isSelected = themeManager.isDarkMode ? 
                    (darkModeOuterRingColor == colorHex) : 
                    (lightModeOuterRingColor == colorHex)
            default:
                isSelected = false
            }
        }
        
        return Button(action: {
            selectedColorIndex = index
            selectedColorType = type
            selectedColorHex = color.toHex()
            
            switch type {
            case "clockFace":
                if themeManager.isDarkMode {
                    darkModeClockFaceColor = color.toHex()
                    initializeSliderPositionWithoutUpdatingSelection()
                } else {
                    lightModeClockFaceColor = color.toHex()
                    initializeSliderPositionWithoutUpdatingSelection()
                }
            case "markers":
                if themeManager.isDarkMode {
                    darkModeMarkersColor = color.toHex()
                    viewModel.darkModeMarkersColor = color.toHex()
                    markersViewModel.darkModeMarkersColor = color.toHex()
                } else {
                    lightModeMarkersColor = color.toHex()
                    viewModel.lightModeMarkersColor = color.toHex()
                    markersViewModel.lightModeMarkersColor = color.toHex()
                }
                markersViewModel.updateCurrentThemeColors()
            case "outerRing":
                if themeManager.isDarkMode {
                    darkModeOuterRingColor = color.toHex()
                    viewModel.darkModeOuterRingColor = color.toHex()
                } else {
                    lightModeOuterRingColor = color.toHex()
                    viewModel.lightModeOuterRingColor = color.toHex()
                }
            default:
                break
            }
        }) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 42, height: 42)
                        .overlay(
                            Circle()
                                .stroke(Color.yellow, lineWidth: 2)
                        )
                        .shadow(color: Color.yellow.opacity(0.6), radius: 4, x: 0, y: 0)
                }
                
                Circle()
                    .fill(color)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.7), lineWidth: isSelected ? 1.5 : 0)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ColorUtils.isLightColor(color) ? .black : .white)
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    func showColorPickerSheet(for type: String) {
        colorPickerType = type
        showColorPickerSheet = true
    }
    
    // Инициализирует положение слайдера на основе текущей яркости цвета
    func initializeSliderPosition() {
        let currentColor = Color(
            hex: themeManager.isDarkMode ? darkModeClockFaceColor : lightModeClockFaceColor
        ) ?? .red
        
        selectedColorType = "clockFace"
        selectedColorHex = themeManager.isDarkMode ? darkModeClockFaceColor : lightModeClockFaceColor
        currentBaseColor = ColorUtils.getBaseColor(forColor: currentColor)
        
        let brightness = ColorUtils.getBrightness(of: currentColor) / ColorUtils.getBrightness(of: currentBaseColor)
        
        if brightness <= 0.7 {
            sliderBrightnessPosition = 1.0
        } else if brightness >= 1.3 {
            sliderBrightnessPosition = 0.0
        } else {
            sliderBrightnessPosition = 1.0 - ((brightness - 0.7) / 0.6)
        }
    }
    
    // Инициализирует положение слайдера без обновления выбранного индекса
    func initializeSliderPositionWithoutUpdatingSelection() {
        let currentColor = Color(
            hex: themeManager.isDarkMode ? darkModeClockFaceColor : lightModeClockFaceColor
        ) ?? .red
        
        currentBaseColor = ColorUtils.getBaseColor(forColor: currentColor)
        
        let brightness = ColorUtils.getBrightness(of: currentColor) / ColorUtils.getBrightness(of: currentBaseColor)
        
        if brightness <= 0.7 {
            sliderBrightnessPosition = 1.0
        } else if brightness >= 1.3 {
            sliderBrightnessPosition = 0.0
        } else {
            sliderBrightnessPosition = 1.0 - ((brightness - 0.7) / 0.6)
        }
    }
} 
