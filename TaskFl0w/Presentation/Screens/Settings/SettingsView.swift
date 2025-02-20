//
//  SettingsView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Тёмный режим", isOn: $isDarkMode)
                } header: {
                    Text("Тема")
                }
                
                Section {
                    NavigationLink(destination: ClockFaceEditorView()) {
                        HStack {
                            Text("Редактировать циферблат")
                            Spacer()
                            Image(systemName: "clock.circle")
                                .foregroundColor(.gray)
                        }
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
        }
    }
}
