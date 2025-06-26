import SwiftUI

struct ColorControlsView: View {
    @ObservedObject var viewModel: ClockViewModel
    @ObservedObject var markersViewModel: ClockMarkersViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Binding var selectedColorType: String
    @Binding var showHandColorSettings: Bool
    @Binding var showColorSettings: Bool
    @State private var selectedColorHex: String = "#FFFFFF"
    @State private var currentBaseColor: Color = .red
    @State private var sliderBrightnessPosition: Double = 0.5
    
    // Цвета циферблата
    @Binding var lightModeClockFaceColor: String
    @Binding var darkModeClockFaceColor: String
    
    // Цвета маркеров
    @Binding var lightModeMarkersColor: String
    @Binding var darkModeMarkersColor: String
    
    // Цвета внешнего кольца
    @Binding var lightModeOuterRingColor: String
    @Binding var darkModeOuterRingColor: String
    
    // Цвета стрелки
    @Binding var lightModeHandColor: String
    @Binding var darkModeHandColor: String
    
    // Добавляем новые свойства в ColorControlsView
    @Binding var lightModeDigitalFontColor: String
    @Binding var darkModeDigitalFontColor: String
    
    @State private var selectedMarkersColorIndex: Int?
    @State private var selectedHandColorIndex: Int?

    // MARK: - Computed Properties
    private var titleText: String {
        switch selectedColorType {
        case "clockFace":
            return "Цвет циферблата"
        case "markers":
            return "Цвет маркеров"
        case "outerRing":
            return "Цвет внешнего кольца"
        case "handColor":
            return "Цвет стрелки"
        case "digitalFontColor":
            return "Цвет цифр"
        default:
            return "Цвет стрелки"
        }
    }
    
    private var buttonForegroundColor: Color {
        themeManager.isDarkMode ? .yellow : .red1
    }
    
    private var buttonStrokeColor: Color {
        themeManager.isDarkMode ? Color.yellow : Color.red1
    }
    
    private var textForegroundColor: Color {
        themeManager.isDarkMode ? .white : .black
    }
    
    private var currentColorForSlider: Color {
        switch selectedColorType {
        case "clockFace":
            return Color(hex: themeManager.isDarkMode ? darkModeClockFaceColor : lightModeClockFaceColor) ?? .red
        case "markers":
            return Color(hex: themeManager.isDarkMode ? darkModeMarkersColor : lightModeMarkersColor) ?? .gray
        default:
            return Color(hex: themeManager.isDarkMode ? darkModeClockFaceColor : lightModeClockFaceColor) ?? .red
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            headerSection
            
            if showHandColorSettings {
                handColorSelectionView
            } else {
                mainColorSelectionView
            }
        }
        .onAppear {
            updateCurrentBaseColor()
        }
        .onChange(of: selectedColorType) { _, _ in
            updateCurrentBaseColor()
        }
    }

    // MARK: - View Components
    @ViewBuilder
    private var headerSection: some View {
        HStack {
            Text(titleText)
                .font(.headline)
                .foregroundColor(textForegroundColor)
            
            Spacer()
            
            if showHandColorSettings {
                createDoneButton {
                    updateSelectedColorType("clockFace")
                    withAnimation {
                        showHandColorSettings = false
                    }
                }
            } else if selectedColorType != "clockFace" {
                createDoneButton {
                    updateSelectedColorType("clockFace")
                }
            }
        }
    }
    
    @ViewBuilder
    private var handColorSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                handColorButton(color: .black, index: 0)
                handColorButton(color: .gray, index: 1)
                handColorButton(color: .Pink1, index: 2)
                handColorButton(color: .red1, index: 3)
                handColorButton(color: .Orange1, index: 4)
                handColorButton(color: .yellow, index: 5)
                handColorButton(color: .green1, index: 6)
                handColorButton(color: .LightBlue1, index: 7)
                handColorButton(color: .Teal1, index: 8)
                handColorButton(color: .blue, index: 9)
                handColorButton(color: .Indigo1, index: 10)
                handColorButton(color: .Purple1, index: 11)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
        .frame(height: 60)
    }
    
    @ViewBuilder
    private var mainColorSelectionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            if selectedColorType != "outerRing" {
                brightnessSliderView
            }
            
            // Остальной контент...
        }
    }
    
    @ViewBuilder
    private var brightnessSliderView: some View {
        ZStack(alignment: .center) {
            gradientBackground
            sliderControl
        }
    }
    
    private var gradientBackground: some View {
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
    }
    
    private var sliderControl: some View {
        GeometryReader { geometry in
            let paddingHorizontal: CGFloat = 30
            let width = geometry.size.width - paddingHorizontal * 2
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
                .gesture(createSliderGesture(paddingHorizontal: paddingHorizontal, width: width, minX: minX))
        }
    }

    // MARK: - Private Methods
    private func createDoneButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Готово")
                .font(.caption)
                .foregroundColor(buttonForegroundColor)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(buttonStrokeColor, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func createSliderGesture(paddingHorizontal: CGFloat, width: CGFloat, minX: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                handleSliderChange(value: value, paddingHorizontal: paddingHorizontal, width: width, minX: minX)
            }
    }
    
    private func handleSliderChange(value: DragGesture.Value, paddingHorizontal: CGFloat, width: CGFloat, minX: CGFloat) {
        let maxX = minX + width
        let xPosition = min(max(value.location.x, minX), maxX)
        sliderBrightnessPosition = (xPosition - minX) / width
        
        let newColor = ColorUtils.getColorAt(
            position: sliderBrightnessPosition,
            baseColor: currentBaseColor
        )
        let newColorHex = newColor.toHex()
        
        updateColorForType(newColorHex: newColorHex)
        selectedColorHex = newColorHex
    }
    
    private func updateColorForType(newColorHex: String) {
        switch selectedColorType {
        case "clockFace":
            updateClockFaceColor(newColorHex)
        case "markers":
            updateMarkersColor(newColorHex)
        case "outerRing":
            updateOuterRingColor(newColorHex)
        case "digitalFontColor":
            updateDigitalFontColor(newColorHex)
        default:
            break
        }
    }
    
    private func updateClockFaceColor(_ newColorHex: String) {
        if themeManager.isDarkMode {
            darkModeClockFaceColor = newColorHex
        } else {
            lightModeClockFaceColor = newColorHex
        }
    }
    
    private func updateMarkersColor(_ newColorHex: String) {
        if themeManager.isDarkMode {
            darkModeMarkersColor = newColorHex
            viewModel.themeConfig.darkModeMarkersColor = newColorHex
            markersViewModel.darkModeMarkersColor = newColorHex
        } else {
            lightModeMarkersColor = newColorHex
            viewModel.themeConfig.lightModeMarkersColor = newColorHex
            markersViewModel.lightModeMarkersColor = newColorHex
        }
        markersViewModel.updateCurrentThemeColors()
    }
    
    private func updateOuterRingColor(_ newColorHex: String) {
        if themeManager.isDarkMode {
            darkModeOuterRingColor = newColorHex
            viewModel.themeConfig.darkModeOuterRingColor = newColorHex
        } else {
            lightModeOuterRingColor = newColorHex
            viewModel.themeConfig.lightModeOuterRingColor = newColorHex
        }
    }
    
    private func updateDigitalFontColor(_ newColorHex: String) {
        if themeManager.isDarkMode {
            darkModeDigitalFontColor = newColorHex
            viewModel.themeConfig.darkModeDigitalFontColor = newColorHex
            markersViewModel.darkModeDigitalFontColor = newColorHex
        } else {
            lightModeDigitalFontColor = newColorHex
            viewModel.themeConfig.lightModeDigitalFontColor = newColorHex
            markersViewModel.lightModeDigitalFontColor = newColorHex
        }
        markersViewModel.updateCurrentThemeColors()
    }
    
    private func updateCurrentBaseColor() {
        currentBaseColor = currentColorForSlider
    }
    
    // MARK: - Missing Function Implementations
    
    private func updateSelectedColorType(_ newType: String) {
        selectedColorType = newType
    }
    
    private func handColorButton(color: Color, index: Int) -> some View {
        Button(action: {
            selectedHandColorIndex = index
            let colorHex = color.toHex()
            
            if themeManager.isDarkMode {
                darkModeHandColor = colorHex
                viewModel.themeConfig.darkModeHandColor = colorHex
            } else {
                lightModeHandColor = colorHex
                viewModel.themeConfig.lightModeHandColor = colorHex
            }
        }) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(
                            selectedHandColorIndex == index ? 
                                (themeManager.isDarkMode ? Color.yellow : Color.red1) : 
                                Color.clear,
                            lineWidth: 3
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
