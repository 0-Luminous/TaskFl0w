//
//  SettingsView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    
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
                
                // Вторая секция
                Section {
                    // Персонализация
                    NavigationLink {
                        PersonalizationView()
                    } label: {
                        SettingsRow(title: "Персонолизация")
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
