//
//  SettingsViewIOS.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI

struct SettingsViewIOS: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Генератор тактильного отклика
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        NavigationView {
            List {
                // Первая секция
                Section {
                    // Профиль пользователя
                    NavigationLink {
                        MyProfileView()
                    } label: {
                        SettingsRow(title: "Мой профиль")
                    }
                    
                    // Потоки задач
                    NavigationLink {
                        Text("Потоки задач")
                    } label: {
                        SettingsRow(title: "Потоки задач")
                    }
                }
                
                // Секция настроек интерфейса
                Section(header: Text("ИНТЕРФЕЙС")) {
                    // Переключатель темной темы
                    Toggle("Тёмная тема", isOn: Binding(
                        get: { themeManager.isDarkMode },
                        set: { newValue in
                            if newValue != themeManager.isDarkMode {
                                // Переключаем тему напрямую в ThemeManager
                                themeManager.toggleDarkMode()
                                
                                // Синхронизируем AppStorage
                                isDarkMode = themeManager.isDarkMode
                                
                                // Применяем эффект вибрации
                                feedbackGenerator.impactOccurred()
                                
                                // Принудительно обновляем UI
                                DispatchQueue.main.async {
                                    themeManager.objectWillChange.send()
                                }
                            }
                        }
                    ))
                    
                    // Персонализация
                    NavigationLink {
                        PersonalizationViewIOS()
                    } label: {
                        SettingsRow(title: "Персонализация")
                    }
                }
                
                // Третья секция
                Section {
                    // Данные и память
                    NavigationLink {
                        Text("Данные и память")
                    } label: {
                        SettingsRow(title: "Данные и память")
                    }
                    
                    // Язык
                    NavigationLink {
                        LanguagesView()
                    } label: {
                        SettingsRow(title: "Язык")
                    }
                    
                    // Уведомления и звук
                    NavigationLink {
                        SoundAndNotification()
                    } label: {
                        SettingsRow(title: "Уведомления и звук")
                    }
                }
            }
            .navigationTitle("НАСТРОЙКИ")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
        // Применяем цветовую схему для всего представления в зависимости от текущей темы
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        .onAppear {
            // Синхронизируем isDarkMode с ThemeManager при появлении
            isDarkMode = themeManager.isDarkMode
        }
    }
}
// Вспомогательное представление для строки настроек
struct SettingsRow: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
        }
    }
}
