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
                // Профиль пользователя
                NavigationLink {
                    Text("Мой профиль")
                } label: {
                    SettingsRow(title: "Мой профиль")
                }
                
                // Персонализация
                NavigationLink {
                    PersonalizationView()
                } label: {
                    SettingsRow(title: "Персонолизация")
                }
                
                // Данные и память
                NavigationLink {
                    Text("Данные и память")
                } label: {
                    SettingsRow(title: "Данные и память")
                }
                
                // Язык
                NavigationLink {
                    Text("Язык")
                } label: {
                    SettingsRow(title: "Язык")
                }
                
                // Уведомления и звук
                NavigationLink {
                    Text("Уведомления и звук")
                } label: {
                    SettingsRow(title: "Уведомления и звук")
                }
                
                // Потоки задач
                Section("Мои потоки задач") {
                    // Здесь можно добавить дополнительные элементы для потоков задач
                }
            }
            .navigationTitle("НАСТРОЙКИ")
            .navigationBarTitleDisplayMode(.large)
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
