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
                    ForEach(0..<tabs.count, id: \.self) { index in
                        dockBarButton(for: index)
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
                        .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                    
                    // Добавляем градиентный бордер
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.5, green: 0.5, blue: 0.5, opacity: 0.5),
                                    Color(red: 0.3, green: 0.3, blue: 0.3, opacity: 0.3),
                                    Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 1)
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
                Image(systemName: tabs[index].icon)
                    .font(.system(size: 20))
                    .foregroundColor(selectedTab == index ? .blue : .gray)
                
                Text(tabs[index].title)
                    .font(.caption)
                    .foregroundColor(selectedTab == index ? .blue : .gray)
            }
            .frame(width: 130)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
        }
    }
}
