//
//  EnhancedWatchFacePreviewCard.swift
//  TaskFl0w
//
//  Created by Yan on 7/5/25.
//

import SwiftUI

// Улучшенная карточка для предпросмотра циферблата
struct EnhancedWatchFacePreviewCard: View {
    let watchFace: WatchFaceModel
    let isSelected: Bool
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack {
            // Миниатюра циферблата
            ZStack {
                // Фон карточки
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.isDarkMode ? 
                        Color(red: 0.18, green: 0.18, blue: 0.18) :
                        Color(red: 0.95, green: 0.95, blue: 0.95))
                    .shadow(color: isSelected ? 
                        (themeManager.isDarkMode ? .yellow.opacity(0.4) : .yellow.opacity(0.3)) : 
                        (themeManager.isDarkMode ? .black.opacity(0.5) : .gray.opacity(0.3)), 
                        radius: 5)
                
                VStack {
                    // Предпросмотр циферблата
                    ZStack {
                        // Внешнее кольцо
                        Circle()
                            .stroke(
                                themeManager.isDarkMode 
                                    ? Color(hex: watchFace.darkModeOuterRingColor) ?? .gray 
                                    : Color(hex: watchFace.lightModeOuterRingColor) ?? .gray,
                                lineWidth: watchFace.outerRingLineWidth * 0.35
                            )
                            .frame(width: 110, height: 110)
                        
                        // Наш новый компонент для отображения циферблата
                        LibraryClockFaceView(watchFace: watchFace)
                            .scaleEffect(0.35)
                            .frame(width: 120, height: 120)
                    }
                    .padding(.top, 12)
                    
                    // Название и статус
                    VStack(spacing: 2) {
                        Text(watchFace.name)
                            .font(.headline)
                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                            .lineLimit(1)
                        
                        if watchFace.isCustom {
                            Text("Пользовательский")
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .gray : .gray.opacity(0.7))
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(width: 160, height: 180)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isSelected 
                        ? LinearGradient(
                            colors: [
                                themeManager.isDarkMode ? 
                                    .yellow : 
                                    .red1,
                                themeManager.isDarkMode ? 
                                    .yellow.opacity(0.6) : 
                                    .red1.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                        : LinearGradient(
                            colors: [
                                themeManager.isDarkMode ? 
                                    Color.gray.opacity(0.5) : 
                                    Color.gray.opacity(0.3),
                                themeManager.isDarkMode ? 
                                    Color.gray.opacity(0.2) : 
                                    Color.gray.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .padding(.vertical, 5)
    }
} 