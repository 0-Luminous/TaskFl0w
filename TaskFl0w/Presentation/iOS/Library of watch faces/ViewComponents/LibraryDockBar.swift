//
//  LibraryDockBar.swift
//  TaskFl0w
//
//  Created by Yan on 10/5/25.
//

import SwiftUI

struct LibraryDockBar: View {
    // MARK: - Properties
    @State private var selectedTab: Int = 0
    @ObservedObject private var themeManager = ThemeManager.shared
    let tabs: [(icon: String, title: String)]
    let onTabSelected: (Int) -> Void
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Основной контейнер с размытым фоном
            HStack(spacing: 0) {
                Spacer()
                
                // Используем фиксированные фреймы для гарантии стабильного положения
                HStack(spacing: 20) {
                    // Кнопка сброса слева
                    Button(action: {
                        withAnimation {
                            selectedTab = 0
                            onTabSelected(0)
                        }
                    }) {
                        HStack(spacing: 8) {
                            // Image(systemName: "arrow.counterclockwise")
                            //     .font(.system(size: 20))
                            //     .foregroundColor(themeManager.isDarkMode ? .gray : .gray.opacity(0.7))
                            
                            Text("Добавить")
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .gray : .black)
                        }
                        .frame(width: 90)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(themeManager.isDarkMode ? 
                                    Color(red: 0.184, green: 0.184, blue: 0.184) :
                                    Color(red: 0.9, green: 0.9, blue: 0.9))
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            themeManager.isDarkMode ? 
                                                Color.gray.opacity(0.7) : 
                                                Color.gray.opacity(0.5),
                                            themeManager.isDarkMode ? 
                                                Color.gray.opacity(0.3) : 
                                                Color.gray.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.0
                                )
                        )
                        .shadow(color: themeManager.isDarkMode ? 
                            .black.opacity(0.3) : 
                            .gray.opacity(0.2), 
                            radius: 3, x: 0, y: 1)
                    }
                    
                    // Центральный переключатель темы
                    ThemeModeToggle()
                        .frame(width: 90)
                    
                    // Кнопка создания справа
                    Button(action: {
                        withAnimation {
                            selectedTab = 1
                            onTabSelected(1)
                        }
                    }) {
                        HStack(spacing: 8) {
                            // Image(systemName: "plus")
                            //     .font(.system(size: 20))
                            //     .foregroundColor(themeManager.isDarkMode ? .gray : .gray.opacity(0.7))
                            
                            Text("Сбросить")
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .gray : .black)
                        }
                        .frame(width: 90)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(themeManager.isDarkMode ? 
                                    Color(red: 0.184, green: 0.184, blue: 0.184) :
                                    Color(red: 0.9, green: 0.9, blue: 0.9))
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            themeManager.isDarkMode ? 
                                                Color.gray.opacity(0.7) : 
                                                Color.gray.opacity(0.5),
                                            themeManager.isDarkMode ? 
                                                Color.gray.opacity(0.3) : 
                                                Color.gray.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.0
                                )
                        )
                        .shadow(color: themeManager.isDarkMode ? 
                            .black.opacity(0.3) : 
                            .gray.opacity(0.2), 
                            radius: 3, x: 0, y: 1)
                    }
                }
                .frame(width: 300)
                
                Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(height: 52)
            .background {
                ZStack {
                    // Размытый фон с уменьшенной шириной
                    Capsule()
                        .fill(themeManager.isDarkMode ? 
                            Color(red: 0.2, green: 0.2, blue: 0.2) :
                            Color(red: 0.95, green: 0.95, blue: 0.95))
                    
                    // Добавляем градиентный бордер
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    themeManager.isDarkMode ?
                                        Color(red: 0.5, green: 0.5, blue: 0.5, opacity: 0.5) :
                                        Color(red: 0.7, green: 0.7, blue: 0.7, opacity: 0.5),
                                    themeManager.isDarkMode ?
                                        Color(red: 0.3, green: 0.3, blue: 0.3, opacity: 0.3) :
                                        Color(red: 0.5, green: 0.5, blue: 0.5, opacity: 0.3),
                                    themeManager.isDarkMode ?
                                        Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.1) :
                                        Color(red: 0.3, green: 0.3, blue: 0.3, opacity: 0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: themeManager.isDarkMode ? 
                    Color.black.opacity(0.25) : 
                    Color.gray.opacity(0.15), 
                    radius: 3, x: 0, y: 1)
            }
        }
        .padding(.horizontal, 50)
        .padding(.bottom, 8)
    }
    
    // MARK: - UI Components
    
    private func dockBarButton(for index: Int) -> some View {
        Button(action: {
            withAnimation {
                selectedTab = index
                onTabSelected(index)
            }
        }) {
            HStack(spacing: 8) {
                // Image(systemName: tabs[index].icon)
                //     .font(.system(size: 20))
                //     .foregroundColor(selectedTab == index ? .blue : 
                //         (themeManager.isDarkMode ? .gray : .gray.opacity(0.7)))
                
                Text(tabs[index].title)
                    .font(.caption)
                    .foregroundColor(selectedTab == index ? .blue : 
                        (themeManager.isDarkMode ? .gray : .gray.opacity(0.7)))
            }
            .frame(width: 90)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(themeManager.isDarkMode ? 
                        Color(red: 0.184, green: 0.184, blue: 0.184) :
                        Color(red: 0.9, green: 0.9, blue: 0.9))
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                themeManager.isDarkMode ? 
                                    Color.gray.opacity(0.7) : 
                                    Color.gray.opacity(0.5),
                                themeManager.isDarkMode ? 
                                    Color.gray.opacity(0.3) : 
                                    Color.gray.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
            .shadow(color: themeManager.isDarkMode ? 
                .black.opacity(0.3) : 
                .gray.opacity(0.2), 
                radius: 3, x: 0, y: 1)
        }
    }
}
