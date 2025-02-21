//
//  ClockFaceEditorView.swift
//  TaskFl0w
//
//  Created by Yan on 20/2/25.
//

import SwiftUI

struct ClockFaceEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("clockStyle") private var clockStyle: ClockStyle = .classic
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("lightModeClockFaceColor") private var lightModeClockFaceColor: String = Color.white.toHex()
    @AppStorage("darkModeClockFaceColor") private var darkModeClockFaceColor: String = Color.black.toHex()
    @AppStorage("lightModeMarkersColor") private var lightModeMarkersColor: String = Color.gray.toHex()
    @AppStorage("darkModeMarkersColor") private var darkModeMarkersColor: String = Color.gray.toHex()
    @AppStorage("showHourNumbers") private var showHourNumbers: Bool = true
    @AppStorage("markersWidth") private var markersWidth: Double = 2.0
    @AppStorage("lightModeOuterRingColor") private var lightModeOuterRingColor: String = Color.gray.opacity(0.3).toHex()
    @AppStorage("darkModeOuterRingColor") private var darkModeOuterRingColor: String = Color.gray.opacity(0.3).toHex()
    @AppStorage("markersOffset") private var markersOffset: Double = 40.0
    @AppStorage("numbersSize") private var numbersSize: Double = 12.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Предпросмотр циферблата
            ClockPreviewView()
                .frame(height: UIScreen.main.bounds.width * 0.8)
                .padding(.vertical, 20)
                .environment(\.colorScheme, isDarkMode ? .dark : .light)
            
            // Настройки
            List {
                Section(header: Text("СТИЛЬ ЦИФЕРБЛАТА")) {
                    HStack {
                        Text("Стиль")
                        Spacer()
                        Text(clockStyle.rawValue.capitalized)
                            .foregroundColor(.gray)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        switch clockStyle {
                        case .classic:
                            clockStyle = .minimal
                        case .minimal:
                            clockStyle = .modern
                        case .modern:
                            clockStyle = .classic
                        }
                    }
                    
                    Toggle("Тёмная тема", isOn: $isDarkMode)
                }
                
                Section(header: Text("ЦВЕТА")) {
                    ColorPicker("Цвет циферблата", selection: Binding(
                        get: {
                            Color(hex: isDarkMode ? darkModeClockFaceColor : lightModeClockFaceColor) ?? (isDarkMode ? .black : .white)
                        },
                        set: { newColor in
                            if isDarkMode {
                                darkModeClockFaceColor = newColor.toHex()
                            } else {
                                lightModeClockFaceColor = newColor.toHex()
                            }
                        }
                    ))
                    
                    ColorPicker("Цвет внешнего круга", selection: Binding(
                        get: {
                            Color(hex: isDarkMode ? darkModeOuterRingColor : lightModeOuterRingColor) ?? .gray.opacity(0.3)
                        },
                        set: { newColor in
                            if isDarkMode {
                                darkModeOuterRingColor = newColor.toHex()
                            } else {
                                lightModeOuterRingColor = newColor.toHex()
                            }
                        }
                    ))
                    
                    ColorPicker("Цвет маркеров", selection: Binding(
                        get: {
                            Color(hex: isDarkMode ? darkModeMarkersColor : lightModeMarkersColor) ?? .gray
                        },
                        set: { newColor in
                            if isDarkMode {
                                darkModeMarkersColor = newColor.toHex()
                            } else {
                                lightModeMarkersColor = newColor.toHex()
                            }
                        }
                    ))
                }
                
                Section(header: Text("МАРКЕРЫ")) {
                    Toggle("Показывать цифры часов", isOn: $showHourNumbers)
                    
                    if showHourNumbers {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Размер цифр")
                            Slider(value: $numbersSize, in: 8...16, step: 1.0)
                                .onChange(of: numbersSize) { _ in
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }
                            HStack {
                                Text("8")
                                    .font(.system(size: 8))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("16")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Толщина маркеров")
                        Slider(value: $markersWidth, in: 1...4, step: 0.5)
                    }
                    .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Расположение маркеров")
                        Slider(value: $markersOffset, in: 20...60, step: 1.0)
                            .onChange(of: markersOffset) { _ in
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                        HStack {
                            Text("Ближе к центру")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("Ближе к краю")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationTitle("Редактор циферблата")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct ClockPreviewView: View {
    @AppStorage("clockStyle") private var clockStyle: ClockStyle = .classic
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("lightModeOuterRingColor") private var lightModeOuterRingColor: String = Color.gray.opacity(0.3).toHex()
    @AppStorage("darkModeOuterRingColor") private var darkModeOuterRingColor: String = Color.gray.opacity(0.3).toHex()
    @AppStorage("markersOffset") private var markersOffset: Double = 40.0
    
    var body: some View {
        ZStack {
            // Внешнее кольцо
            Circle()
                .stroke(currentOuterRingColor, lineWidth: 20)
                .padding(10)
            
            // Циферблат
            Circle()
                .fill(currentClockFaceColor)
                .padding(30)
            
            // Маркеры
            ForEach(0..<24) { hour in
                let angle = Double(hour) * (360.0 / 24.0)
                MainClockMarker(hour: hour, style: clockStyle.markerStyle)
                    .rotationEffect(.degrees(angle))
                    .frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.width * 0.7)
            }
            
            // Стрелка часов (для демонстрации)
            MainClockHandView(currentDate: Date())
                .frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.width * 0.7)
        }
    }
    
    private var currentClockFaceColor: Color {
        let hexColor = colorScheme == .dark
            ? UserDefaults.standard.string(forKey: "darkModeClockFaceColor") ?? Color.black.toHex()
            : UserDefaults.standard.string(forKey: "lightModeClockFaceColor") ?? Color.white.toHex()
        return Color(hex: hexColor) ?? (colorScheme == .dark ? .black : .white)
    }
    
    private var currentOuterRingColor: Color {
        let hexColor = colorScheme == .dark ? darkModeOuterRingColor : lightModeOuterRingColor
        return Color(hex: hexColor) ?? .gray.opacity(0.3)
    }
}

#Preview {
    ClockFaceEditorView()
}

