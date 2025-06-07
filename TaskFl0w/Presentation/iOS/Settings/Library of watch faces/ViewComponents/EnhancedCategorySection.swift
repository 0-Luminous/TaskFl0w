//
//  EnhancedCategorySection.swift
//  TaskFl0w
//
//  Created by Yan on 7/5/25.
//

import SwiftUI

// Улучшенная секция для категории циферблатов
struct EnhancedCategorySection: View {
    let category: WatchFaceCategory
    let watchFaces: [WatchFaceModel]
    let libraryManager: WatchFaceLibraryManager
    var selectedFaceID: UUID? = nil
    let onWatchFaceSelected: (WatchFaceModel) -> Void
    let onEdit: (WatchFaceModel) -> Void
    let onDelete: (WatchFaceModel) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Заголовок категории
            HStack {
                Image(systemName: category.systemImage)
                    .font(.headline)
                    .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                Text(category.localizedName)
                    .font(.headline)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
            }
            .padding(.horizontal)
            
            if watchFaces.isEmpty {
                Text("Нет циферблатов в этой категории")
                    .foregroundColor(themeManager.isDarkMode ? .gray : .gray.opacity(0.7))
                    .italic()
                    .padding(.horizontal)
                    .padding(.vertical, 10)
            } else {
                // Горизонтальный скролл циферблатов
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(watchFaces) { face in
                            EnhancedWatchFacePreviewCard(
                                watchFace: face, 
                                isSelected: selectedFaceID == face.id
                            )
                            .onTapGesture {
                                onWatchFaceSelected(face)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
            }
            
            Divider()
                .background(themeManager.isDarkMode ? 
                    Color.gray.opacity(0.3) : 
                    Color.gray.opacity(0.2))
                .padding(.horizontal)
        }
    }
} 
