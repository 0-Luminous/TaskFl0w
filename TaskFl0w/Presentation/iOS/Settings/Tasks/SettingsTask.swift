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
    
    // Используем AppStorage для сохранения настроек между сессиями
    @AppStorage("moveUnfinishedTasks") private var moveUnfinishedTasks = false
    @AppStorage("increasePriority") private var increasePriority = false
    @AppStorage("priorityIncreaseFrequency") private var priorityIncreaseFrequency = 0 // 0 - каждый день, 1 - раз в два дня, 2 - раз в три дня
    
    private let frequencyOptions = [
        (0, "settingsTask.frequencyEveryDay".localized),
        (1, "settingsTask.frequencyEveryTwoDays".localized),
        (2, "settingsTask.frequencyEveryThreeDays".localized)
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("settingsTask.moveUnfinished".localized, isOn: $moveUnfinishedTasks)
                        .onChange(of: moveUnfinishedTasks) { _, newValue in
                            if !newValue {
                                // Если отключили перенос задач, отключаем и повышение приоритета
                                increasePriority = false
                            }
                        }
                    
                    if moveUnfinishedTasks {
                        Toggle("settingsTask.increasePriority".localized, isOn: $increasePriority)
                            .onChange(of: increasePriority) { _, newValue in
                                // При отключении повышения приоритета сбрасываем частоту
                                if !newValue {
                                    priorityIncreaseFrequency = 0
                                }
                            }
                        
                        if increasePriority {
                            Picker("settingsTask.priorityFrequency".localized, selection: $priorityIncreaseFrequency) {
                                ForEach(frequencyOptions, id: \.0) { option in
                                    Text(option.1).tag(option.0)
                                }
                            }
                        }
                    }
                } header: {
                    Text("settingsTask.sectionHeader".localized)
                } footer: {
                    Text("settingsTask.sectionFooter".localized)
                }
            }
            .navigationTitle("settingsTask.navTitle".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.backward")
                                .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                            Text("navigation.back".localized)
                                .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        saveSettings()
                        dismiss()
                    }) {
                        Text("navigation.done".localized)
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
    
    // Функция для сохранения настроек
    private func saveSettings() {
        // Настройки уже сохраняются автоматически через @AppStorage
        // Но здесь можно добавить любую дополнительную логику
        
        // Синхронизируем UserDefaults
        UserDefaults.standard.synchronize()
        
        // При необходимости можно выполнить дополнительные действия
        print("🔄 Настройки задач сохранены: перенос=\(moveUnfinishedTasks), повышение приоритета=\(increasePriority), частота=\(priorityIncreaseFrequency)")
    }
}

#Preview {
    SettingsTask()
}

