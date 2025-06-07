//
//  SelectWatch.swift
//  TaskFl0w
//
//  Created by Yan on 15/5/25.
//

import SwiftUI

// MARK: - Экран выбора стартового циферблата
struct SelectWatch: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var libraryManager = WatchFaceLibraryManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var selectedWatchFace: WatchFaceModel?
    @State private var localSelectedFaceID: UUID?
    @State private var navigateToSelectCategory = false

    // Модификатор для стилизации кнопок (такой же, как в библиотеке)
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
                // .padding(.vertical, 6)
                // .padding(.horizontal, 10)
                .foregroundColor(
                    isSelected
                        ? .yellow
                        : (isDisabled ? .gray : (themeManager.isDarkMode ? .white : .black))
                )
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(
                            themeManager.isDarkMode
                                ? Color(red: 0.184, green: 0.184, blue: 0.184).opacity(
                                    isDisabled ? 0.5 : 1)
                                : Color(red: 0.95, green: 0.95, blue: 0.95).opacity(
                                    isDisabled ? 0.5 : 1))
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
                .shadow(
                    color: themeManager.isDarkMode ? .black.opacity(0.3) : .gray.opacity(0.2),
                    radius: 3, x: 0, y: 1
                )
                .opacity(isDisabled ? 0.6 : 1)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Фон
                Color(
                    themeManager.isDarkMode
                        ? Color(red: 0.098, green: 0.098, blue: 0.098)
                        : Color(red: 0.98, green: 0.98, blue: 0.98)
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Добавляем отступ для заголовка
                    // Spacer().frame(height: 50)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {

                            Spacer().frame(height: 50)

                            // Отображаем каждую категорию с её циферблатами
                            ForEach(WatchFaceCategory.allCases) { category in
                                EnhancedCategorySection(
                                    category: category,
                                    watchFaces: libraryManager.watchFaces(for: category),
                                    libraryManager: libraryManager,
                                    selectedFaceID: localSelectedFaceID,
                                    onWatchFaceSelected: { face in
                                        localSelectedFaceID = face.id
                                        selectedWatchFace = face
                                        // Не вызываем dismiss() и не сохраняем пока в UserDefaults
                                    },
                                    onEdit: { _ in },  // Пустая функция вместо nil
                                    onDelete: { _ in }  // Пустая функция вместо nil
                                )
                                // .padding(.horizontal)
                            }

                            Spacer().frame(height: 80)
                        }
                        // .padding(.top)
                    }
                }

                // Заголовок выше основного контента
                VStack {
                    // Небольшой отступ сверх
                    HStack {
                        Image(systemName: "clock.circle")
                            .foregroundColor(themeManager.isDarkMode ? .coral1 : .red1)
                            .font(.system(size: 16))

                        Text("firstView.selectWatch".localized())
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    .background {
                        // Размытый фон
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .environment(
                                \.colorScheme, themeManager.isDarkMode ? .dark : .light
                            )
                            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)

                    Spacer()
                }

                // Кнопка внизу для продолжения
                VStack {
                    Spacer()
                    NavigationLink(
                        destination: SelectCategory(), isActive: $navigateToSelectCategory
                    ) {
                        EmptyView()
                    }
                    .hidden()

                    Button(action: {
                        // Проверяем, был ли выбран циферблат
                        if let selectedID = localSelectedFaceID {
                            libraryManager.selectWatchFace(selectedID)
                            // Сохраняем ID выбранного циферблата в UserDefaults
                            UserDefaults.standard.set(
                                selectedID.uuidString, forKey: "startupWatchFaceID")
                        } else {
                            // Если пользователь не выбрал циферблат, используем первый доступный
                            for category in WatchFaceCategory.allCases {
                                let faces = libraryManager.watchFaces(for: category)
                                if let firstFace = faces.first {
                                    libraryManager.selectWatchFace(firstFace.id)
                                    // Сохраняем ID выбранного циферблата в UserDefaults
                                    UserDefaults.standard.set(
                                        firstFace.id.uuidString, forKey: "startupWatchFaceID")
                                    break
                                }
                            }
                        }
                        navigateToSelectCategory = true
                    }) {
                        Text("navigation.continue".localized())
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        localSelectedFaceID == nil
                                            ? AnyShapeStyle(.ultraThinMaterial)
                                            : AnyShapeStyle(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.Blue1,
                                                        Color.Purple1,
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                            )
                            .foregroundColor(
                                localSelectedFaceID == nil
                                    ? (themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
                                    : .black
                            )
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(themeManager.isDarkMode ? .dark : .light, for: .navigationBar)
        }
    }
}

// MARK: - Расширение для предпросмотра в SwiftUI
struct SelectWatch_Previews: PreviewProvider {
    static var previews: some View {
        SelectWatch()
    }
}
