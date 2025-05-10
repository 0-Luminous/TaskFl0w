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
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            // Миниатюра циферблата
            ZStack {
                // Фон карточки
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.18, green: 0.18, blue: 0.18))
                    .shadow(color: isSelected ? .yellow.opacity(0.4) : .black.opacity(0.5), radius: 5)
                
                VStack {
                    // Предпросмотр циферблата
                    ZStack {
                        // Внешнее кольцо
                        Circle()
                            .stroke(
                                colorScheme == .dark 
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
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if watchFace.isCustom {
                            Text("Пользовательский")
                                .font(.caption)
                                .foregroundColor(.gray)
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
                            colors: [.yellow, .yellow.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                        : LinearGradient(
                            colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .padding(.vertical, 5)
    }
} 