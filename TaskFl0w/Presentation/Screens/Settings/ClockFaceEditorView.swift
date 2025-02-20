//
//  ClockFaceEditorView.swift
//  TaskFl0w
//
//  Created by Yan on 20/2/25.
//

import SwiftUI

struct ClockFaceEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("clockStyle") private var clockStyle: ClockStyle = .classic
    @AppStorage("lightModeClockFaceColor") private var lightModeClockFaceColor: String = Color.white.toHex()
    @AppStorage("darkModeClockFaceColor") private var darkModeClockFaceColor: String = Color.black.toHex()
    @AppStorage("showHourNumbers") private var showHourNumbers: Bool = true
    @AppStorage("markersColor") private var markersColor: String = Color.gray.toHex()
    @AppStorage("markersWidth") private var markersWidth: Double = 2.0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Стиль циферблата")) {
                    Picker("Стиль", selection: $clockStyle) {
                        ForEach(ClockStyle.allCases, id: \.self) { style in
                            Text(style.rawValue.capitalized).tag(style)
                        }
                    }
                }
                
                Section(header: Text("Цвета")) {
                    ColorPicker("Цвет циферблата (Светлая тема)", selection: Binding(
                        get: { Color(hex: lightModeClockFaceColor) ?? .white },
                        set: { lightModeClockFaceColor = $0.toHex() }
                    ))
                    
                    ColorPicker("Цвет циферблата (Тёмная тема)", selection: Binding(
                        get: { Color(hex: darkModeClockFaceColor) ?? .black },
                        set: { darkModeClockFaceColor = $0.toHex() }
                    ))
                    
                    ColorPicker("Цвет маркеров", selection: Binding(
                        get: { Color(hex: markersColor) ?? .gray },
                        set: { markersColor = $0.toHex() }
                    ))
                }
                
                Section(header: Text("Маркеры")) {
                    Toggle("Показывать цифры часов", isOn: $showHourNumbers)
                    
                    VStack(alignment: .leading) {
                        Text("Толщина маркеров")
                        Slider(value: $markersWidth, in: 1...4, step: 0.5)
                    }
                }
                
                // Предпросмотр
                Section(header: Text("Предпросмотр")) {
                    ClockPreviewView()
                        .frame(height: 200)
                }
            }
            .navigationTitle("Редактор циферблата")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ClockPreviewView: View {
    @AppStorage("clockStyle") private var clockStyle: ClockStyle = .classic
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Circle()
                .fill(currentClockFaceColor)
                .stroke(Color.gray, lineWidth: 2)
            
            // Предпросмотр маркеров в соответствии с выбранным стилем
            ForEach(0..<24) { hour in
                let angle = Double(hour) * (360.0 / 24.0)
                MainClockMarker(hour: hour, style: clockStyle.markerStyle)
                    .rotationEffect(.degrees(angle))
            }
        }
        .padding()
    }
    
    private var currentClockFaceColor: Color {
        let hexColor = colorScheme == .dark
            ? UserDefaults.standard.string(forKey: "darkModeClockFaceColor") ?? Color.black.toHex()
            : UserDefaults.standard.string(forKey: "lightModeClockFaceColor") ?? Color.white.toHex()
        return Color(hex: hexColor) ?? .white
    }
}

#Preview {
    ClockFaceEditorView()
}

