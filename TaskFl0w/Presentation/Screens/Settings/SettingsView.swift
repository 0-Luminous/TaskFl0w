//
//  SettingsView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Можно использовать прямо @AppStorage("isDarkMode"), если нужно
    // или же @ObservedObject var viewModel: ClockViewModel, если настройки в модели
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    @AppStorage("lightModeClockFaceColor") private var lightModeClockFaceColor = Color.white.toHex()
    @AppStorage("darkModeClockFaceColor") private var darkModeClockFaceColor = Color.black.toHex()
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Тёмный режим", isOn: $isDarkMode)
                } header: {
                    Text("Тема")
                }
                
                Section {
                    ColorPicker("Цвет циферблата (Светлая тема)", selection: Binding(get: {
                        Color(hex: lightModeClockFaceColor) ?? .white
                    }, set: { newColor in
                        lightModeClockFaceColor = newColor.toHex()
                    }))
                    
                    ColorPicker("Цвет циферблата (Тёмная тема)", selection: Binding(get: {
                        Color(hex: darkModeClockFaceColor) ?? .black
                    }, set: { newColor in
                        darkModeClockFaceColor = newColor.toHex()
                    }))
                } header: {
                    Text("Цвета циферблата")
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
}
