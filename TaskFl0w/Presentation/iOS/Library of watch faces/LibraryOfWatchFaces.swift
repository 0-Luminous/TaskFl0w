//
//  LibraryOfWatchFaces.swift
//  TaskFl0w
//
//  Created by Yan on 7/5/25.
//

import SwiftUI

// MARK: - Просмотр библиотеки циферблатов
struct LibraryOfWatchFaces: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var libraryManager = WatchFaceLibraryManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var newWatchFaceName = ""
    @State private var selectedWatchFace: WatchFaceModel?
    @State private var showDeleteAllAlert = false
    
    // Модификатор для стилизации кнопок
    private struct ButtonModifier: ViewModifier {
        let isSelected: Bool
        let isDisabled: Bool
        @ObservedObject private var themeManager = ThemeManager.shared
        
        init(isSelected: Bool = false, isDisabled: Bool = false) {
            self.isSelected = isSelected
            self.isDisabled = isDisabled
        }
        
        func body(content: Content) -> some View {
            content
                .font(.caption)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .foregroundColor(isSelected ? .yellow : (isDisabled ? .gray : (themeManager.isDarkMode ? .white : .black)))
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(themeManager.isDarkMode ? 
                            Color(red: 0.184, green: 0.184, blue: 0.184).opacity(isDisabled ? 0.5 : 1) :
                            Color(red: 0.95, green: 0.95, blue: 0.95).opacity(isDisabled ? 0.5 : 1))
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(isDisabled ? 0.3 : 0.7),
                                    Color.gray.opacity(isDisabled ? 0.1 : 0.3),
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isDisabled ? 0.5 : 1.0
                        )
                )
                .shadow(color: themeManager.isDarkMode ? .black.opacity(0.3) : .gray.opacity(0.2), radius: 3, x: 0, y: 1)
                .opacity(isDisabled ? 0.6 : 1)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Фон
                Color(themeManager.isDarkMode ? 
                    Color(red: 0.098, green: 0.098, blue: 0.098) :
                    Color(red: 0.98, green: 0.98, blue: 0.98))
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Отображаем каждую категорию с её циферблатами
                            ForEach(WatchFaceCategory.allCases) { category in
                                EnhancedCategorySection(
                                    category: category,
                                    watchFaces: libraryManager.watchFaces(for: category),
                                    libraryManager: libraryManager,
                                    onWatchFaceSelected: { face in
                                        libraryManager.selectWatchFace(face.id)
                                        dismiss()
                                    },
                                    onEdit: { face in
                                        selectedWatchFace = face
                                        showingEditSheet = true
                                    },
                                    onDelete: { face in
                                        libraryManager.deleteWatchFace(face.id)
                                    }
                                )
                                .padding(.horizontal)
                            }
                            
                            Spacer().frame(height: 100)
                        }
                        .padding(.top)
                    }
                }
                
                // Добавляем докбар
                VStack {
                    Spacer()
                    LibraryDockBar(
                        tabs: [
                            ("plus.circle.fill", "Добавить"),
                            ("trash.fill", "Сбросить")
                        ],
                        onTabSelected: { index in
                            switch index {
                            case 0:
                                showingAddSheet = true
                            case 1:
                                showDeleteAllAlert = true
                            default:
                                break
                            }
                        }
                    )
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                }
            }
            .navigationTitle("Библиотека циферблатов")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(themeManager.isDarkMode ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
               EnhancedAddWatchFaceView()
            }
            .sheet(isPresented: $showingEditSheet, onDismiss: {
                selectedWatchFace = nil
            }) {
                if let face = selectedWatchFace {
                    EnhancedEditWatchFaceView(watchFace: face)
                }
            }
            .alert("Сбросить библиотеку?", isPresented: $showDeleteAllAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Сбросить", role: .destructive) {
                    libraryManager.clearAllWatchFaces()
                }
            } message: {
                Text("Будут удалены все пользовательские циферблаты и восстановлены предустановленные. Это действие нельзя отменить.")
            }
        }
    }
}

// MARK: - Расширение для предпросмотра в SwiftUI
struct LibraryOfWatchFaces_Previews: PreviewProvider {
    static var previews: some View {
        LibraryOfWatchFaces()
    }
}
