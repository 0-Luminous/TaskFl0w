//
//  SettingsViewIpad.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI

struct SettingsViewIpad: View {
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
                        SettingsRowIpad(title: "Мой профиль")
                    }
                    
                    // Потоки задач
                    NavigationLink {
                        Text("Потоки задач")
                    } label: {
                        SettingsRowIpad(title: "Потоки задач")
                    }
                }
                
                // Вторая секция
                Section {
                    // Персонализация
                    NavigationLink {
                        PersonalizationViewIOS()
                    } label: {
                        SettingsRowIpad(title: "Персонолизация")
                    }
                }
                
                // Третья секция
                Section {
                    // Данные и память
                    NavigationLink {
                        Text("Данные и память")
                    } label: {
                        SettingsRowIpad(title: "Данные и память")
                    }
                    
                    // Язык
                    NavigationLink {
                        LanguagesView()
                    } label: {
                        SettingsRowIpad(title: "Язык")
                    }
                    
                    // Уведомления и звук
                    NavigationLink {
                        SoundAndNotification()
                    } label: {
                        SettingsRowIpad(title: "Уведомления и звук")
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

// Переименовываем структуру, чтобы избежать конфликта
struct SettingsRowIpad: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
        }
    }
}
