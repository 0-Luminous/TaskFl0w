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
    
    @State private var showingClockFaceEditor = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Тёмный режим", isOn: $isDarkMode)
                } header: {
                    Text("Тема")
                }
                
                Section {
                    Button("Редактировать циферблат") {
                        showingClockFaceEditor = true
                    }
                } header: {
                    Text("Циферблат")
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
            .sheet(isPresented: $showingClockFaceEditor) {
                ClockFaceEditorView()
            }
        }
    }
}
