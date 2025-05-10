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
    let onWatchFaceSelected: (WatchFaceModel) -> Void
    let onEdit: (WatchFaceModel) -> Void
    let onDelete: (WatchFaceModel) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Заголовок категории
            HStack {
                Image(systemName: category.systemImage)
                    .font(.headline)
                    .foregroundColor(.yellow)
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            if watchFaces.isEmpty {
                Text("Нет циферблатов в этой категории")
                    .foregroundColor(.gray)
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
                                isSelected: libraryManager.selectedFaceID == face.id
                            )
                            .onTapGesture {
                                onWatchFaceSelected(face)
                            }
                            // .contextMenu {
                            //     if face.isCustom {
                            //         Button {
                            //             onEdit(face)
                            //         } label: {
                            //             Label("Редактировать", systemImage: "pencil")
                            //         }
                                    
                            //         Button(role: .destructive) {
                            //             onDelete(face)
                            //         } label: {
                            //             Label("Удалить", systemImage: "trash")
                            //         }
                            //     }
                            // }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.horizontal)
        }
    }
} 