//
//  SettingsTask.swift
//  TaskFl0w
//
//  Created by Yan on 11/5/25.
//

import SwiftUI

struct SettingsTask: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @State private var moveUnfinishedTasks = false
    @State private var increasePriority = false
    @State private var priorityIncreaseFrequency = 0 // 0 - каждый день, 1 - раз в два дня, 2 - раз в три дня
    
    private let frequencyOptions = [
        (0, "Каждый день"),
        (1, "Раз в два дня"),
        (2, "Раз в три дня")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Переносить невыполненные задачи", isOn: $moveUnfinishedTasks)
                    
                    if moveUnfinishedTasks {
                        Toggle("Повышать приоритет при переносе", isOn: $increasePriority)
                        
                        if increasePriority {
                            Picker("Частота повышения приоритета", selection: $priorityIncreaseFrequency) {
                                ForEach(frequencyOptions, id: \.0) { option in
                                    Text(option.1).tag(option.0)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Перенос задач")
                } footer: {
                    Text("Невыполненные задачи будут автоматически переноситься на текущий день")
                }
            }
            .navigationTitle("Настройки задач")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.backward")
                                .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                            Text("Назад")
                                .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Здесь будет код для сохранения настроек
                        dismiss()
                    }) {
                        Text("Готово")
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                    }
                }
            }
            .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
            .background(themeManager.isDarkMode ? 
                Color(red: 0.098, green: 0.098, blue: 0.098) : 
                Color(red: 0.95, green: 0.95, blue: 0.95))
        }
    }
}

#Preview {
    SettingsTask()
}

