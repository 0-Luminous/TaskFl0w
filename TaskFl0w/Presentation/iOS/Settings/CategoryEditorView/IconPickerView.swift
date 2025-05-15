//
//  IconPickerView.swift
//  TaskFl0w
//
//  Created by Yan on 29/4/25.
//

import SwiftUI
import UIKit

struct IconPickerView: View {
    @Binding var selectedIcon: String
    let iconColor: Color
    @Binding var isPresented: Bool
    @State private var searchText: String = ""
    @State private var isSearchActive: Bool = false
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Анимация для появления элементов
    @State private var appearAnimation = false
    
    // Добавляем состояние для текущей выбранной категории
    @State private var selectedCategory: IconCategory = .all
    
    // Определяем перечисление для категорий
    enum IconCategory: String, CaseIterable, Identifiable {
        case all = "Все"
        case workAndEducation = "Работа и учёба"
        case homeAndFamily = "Дом и семья"
        case creativityAndHobbies = "Творчество"
        case shoppingAndFinance = "Покупки"
        case travelAndTransport = "Транспорт"
        case timeAndPlanning = "Планирование"
        case communicationAndTech = "Связь"
        case toolsAndSettings = "Инструменты"
        
        var id: String { rawValue }
        
        var systemName: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .workAndEducation: return "briefcase.fill"
            case .homeAndFamily: return "house.fill"
            case .creativityAndHobbies: return "paintbrush.fill"
            case .shoppingAndFinance: return "cart.fill"
            case .travelAndTransport: return "car.fill"
            case .timeAndPlanning: return "calendar"
            case .communicationAndTech: return "phone.fill"
            case .toolsAndSettings: return "gear.circle.fill"
            }
        }
        
        var icons: [String] {
            switch self {
            case .all: return SystemIcons.available
            case .workAndEducation: return SystemIcons.workAndEducation
            case .homeAndFamily: return SystemIcons.homeAndFamily
            case .creativityAndHobbies: return SystemIcons.creativityAndHobbies
            case .shoppingAndFinance: return SystemIcons.shoppingAndFinance
            case .travelAndTransport: return SystemIcons.travelAndTransport
            case .timeAndPlanning: return SystemIcons.timeAndPlanning
            case .communicationAndTech: return SystemIcons.communicationAndTech
            case .toolsAndSettings: return SystemIcons.toolsAndSettings
            }
        }
    }

    private var filteredIcons: [String] {
        let icons = selectedCategory.icons
        
        if searchText.isEmpty {
            return icons
        } else {
            return icons.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            IconSearchBar(text: $searchText, isActive: $isSearchActive)
                .padding(.horizontal)
                .padding(.top, 8)
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : -10)

            ZStack {
                // Основное содержимое с иконками
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 75, maximum: 85))
                        ], spacing: 15
                    ) {
                        ForEach(Array(filteredIcons.enumerated()), id: \.element) { index, icon in
                            Button(action: {
                                selectedIcon = icon
                                feedbackGenerator.impactOccurred()
                                
                                // Добавляем небольшую задержку перед закрытием для лучшего UX
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    // Анимация выбора
                                }
                                
                                // Задержка перед закрытием
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    isPresented = false
                                }
                            }) {
                                VStack(spacing: 8) {
                                    ZStack {
                                        // Слой с тенью
                                        Circle()
                                            .fill(iconColor)
                                            .frame(width: 56, height: 56)
                                            .shadow(color: iconColor.opacity(0.4), radius: 4, x: 0, y: 2)
                                        
                                        // Блик сверху (тонкий градиент)
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.3), .clear],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 56, height: 56)
                                            .blendMode(.overlay)

                                        Image(systemName: icon)
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(.white)
                                    }

                                    Text(icon)
                                        .font(.system(size: 11, weight: icon == selectedIcon ? .medium : .regular))
                                        .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.8) : .black.opacity(0.8))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .frame(width: 75)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        icon == selectedIcon
                                            ? (themeManager.isDarkMode
                                                ? Color(red: 0.22, green: 0.22, blue: 0.22)
                                                : Color(red: 0.95, green: 0.95, blue: 0.95).opacity(0.8)) 
                                            : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                icon == selectedIcon ? iconColor.opacity(0.5) : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                            )
                            .scaleEffect(icon == selectedIcon ? 1.07 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIcon)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.7)
                                .delay(Double(index % 20) * 0.02),
                                value: appearAnimation
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 90)
                }
                
                VStack {
                    Spacer()
                    // Докбар для категорий с улучшенным стилем
                    IconPickerDockBar(selectedCategory: $selectedCategory)
                }
            }
            .navigationTitle("Выбор иконки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(themeManager.isDarkMode ? Color(red: 0.098, green: 0.098, blue: 0.098) : Color(red: 0.95, green: 0.95, blue: 0.95), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(themeManager.isDarkMode ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        feedbackGenerator.impactOccurred()
                        isPresented = false
                    }
                    .foregroundColor(themeManager.isDarkMode ? .coral1 : .red1)
                    .font(.system(size: 17, weight: .medium))
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        feedbackGenerator.impactOccurred()
                        isPresented = false
                    }
                    .foregroundColor(themeManager.isDarkMode ? .coral1 : .red1)
                    .font(.system(size: 17, weight: .regular))
                }
            }
        }
        .background(
            themeManager.isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.12) : Color(red: 0.95, green: 0.95, blue: 0.95)
        )
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            // Запускаем анимацию появления при загрузке
            withAnimation(.easeOut(duration: 0.4)) {
                appearAnimation = true
            }
        }
    }
}

// Улучшенный компонент докбара для категорий
struct IconPickerDockBar: View {
    @Binding var selectedCategory: IconPickerView.IconCategory
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Разбивка на страницы для категорий при необходимости
    @State private var currentPage = 0

    
    private var currentCategories: [IconPickerView.IconCategory] {
        let itemsPerPage = UIDevice.current.userInterfaceIdiom == .pad ? 9 : 5
        let startIndex = currentPage * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, IconPickerView.IconCategory.allCases.count)
        
        return Array(IconPickerView.IconCategory.allCases[startIndex..<endIndex])
    }
    
    var body: some View {
        VStack(spacing: 5) {
            // Основное содержимое с категориями
            categoryGrid
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(themeManager.isDarkMode ? Color(red: 0.16, green: 0.16, blue: 0.16) : Color.white)
                .shadow(
                    color: Color.black.opacity(themeManager.isDarkMode ? 0.25 : 0.08),
                    radius: 4,
                    x: 0,
                    y: 1
                )
        )
        .padding(.horizontal, 10)
        .padding(.bottom, 20)
    }
    
    // Сетка категорий
    private var categoryGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(currentCategories) { category in
                    categoryButton(for: category)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    // Кнопка категории
    private func categoryButton(for category: IconPickerView.IconCategory) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = category
            }
            // Добавляем тактильный отклик
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    // Фоновый круг для выделенной категории
                    if selectedCategory == category {
                        Circle()
                            .fill(
                                themeManager.isDarkMode 
                                    ? LinearGradient(
                                        colors: [Color.coral1.opacity(0.3), Color.coral1.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.red1.opacity(0.25), Color.red1.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                            .frame(width: 58, height: 58)
                    }
                    
                    // Блик сверху для выделенной категории
                    if selectedCategory == category {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 58, height: 58)
                            .blendMode(.overlay)
                    }
                    
                    // Иконка категории
                    Image(systemName: category.systemName)
                        .font(.system(size: 24, weight: selectedCategory == category ? .semibold : .regular))
                        .foregroundColor(
                            selectedCategory == category
                                ? (themeManager.isDarkMode ? .coral1 : .red1)
                                : (themeManager.isDarkMode ? .white.opacity(0.8) : .gray)
                        )
                        .frame(width: 50, height: 50)
                        .background(
                            selectedCategory == category ?
                                Circle()
                                    .stroke(
                                        themeManager.isDarkMode ? Color.coral1 : Color.red1,
                                        lineWidth: 1.5
                                    )
                                    .frame(width: 56, height: 56)
                                : nil
                        )
                }
                
                // Название категории
                Text(category.rawValue)
                    .font(.system(size: 12, weight: selectedCategory == category ? .semibold : .regular))
                    .foregroundColor(
                        selectedCategory == category
                            ? (themeManager.isDarkMode ? .coral1 : .red1)
                            : (themeManager.isDarkMode ? .white.opacity(0.6) : .gray)
                    )
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .opacity(selectedCategory == category ? 1.0 : 0.8)
            }
            .frame(width: 75, height: 75)
            .contentShape(Rectangle()) // Улучшение области нажатия
            .scaleEffect(selectedCategory == category ? 1.03 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCategory)
        }
    }
}

struct IconSearchBar: View {
    @Binding var text: String
    @Binding var isActive: Bool
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var isFocused: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    // Вспомогательные вычисляемые свойства для упрощения кода
    private var isActiveFocus: Bool {
        isTextFieldFocused || isFocused
    }
    
    private var hasText: Bool {
        !text.isEmpty
    }
    
    private var backgroundColor: Color {
        themeManager.isDarkMode 
            ? Color(red: 0.15, green: 0.15, blue: 0.15) 
            : Color.white
    }
    
    private var accentColor: Color {
        themeManager.isDarkMode ? .coral1 : .red1
    }
    
    private var textColor: Color {
        themeManager.isDarkMode ? .white : .black
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Верхний индикатор активности поиска (стилизован как pageIndicator в DockBar)
            if isActiveFocus {
                HStack(spacing: 4) {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 6, height: 6)
                    
                    if hasText {
                        Text("Поиск: \(text)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                    } else {
                        Text("Введите запрос для поиска")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.5) : .black.opacity(0.5))
                    }
                }
                .padding(.bottom, 6)
                .transition(.opacity)
            }
            
            // Основной контейнер поисковой строки (стилизованный как categoryGrid в DockBar)
            HStack(spacing: 10) {
                // Иконка поиска
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: isActiveFocus ? .medium : .regular))
                    .foregroundColor(isActiveFocus || hasText ? accentColor : (themeManager.isDarkMode ? .white.opacity(0.7) : .gray))
                    .frame(width: 20)
                
                // Текстовое поле
                TextField("",
                    text: $text,
                    prompt: Text("Поиск иконки")
                        .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                    )
                    .focused($isTextFieldFocused)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .font(.system(size: 15))
                    .foregroundColor(textColor)
                    .padding(.vertical, 8)
                    .onChange(of: isTextFieldFocused) { newValue in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isFocused = newValue
                            isActive = newValue
                        }
                    }
                    .submitLabel(.search)
                    .onSubmit {
                        if text.isEmpty {
                            isTextFieldFocused = false
                        }
                    }
                
                // Кнопка очистки или отмены поиска
                if hasText {
                    Button(action: {
                        text = ""
                        feedbackGenerator.impactOccurred()
                        isTextFieldFocused = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .transition(.scale.combined(with: .opacity))
                } else if isActiveFocus {
                    Button("Отмена") {
                        text = ""
                        isTextFieldFocused = false
                        feedbackGenerator.impactOccurred()
                        withAnimation {
                            isFocused = false
                            isActive = false
                        }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(accentColor)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .shadow(
                        color: Color.black.opacity(themeManager.isDarkMode ? 0.3 : 0.1),
                        radius: 3,
                        x: 0,
                        y: 1
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isActiveFocus 
                        ? accentColor.opacity(0.5)
                        : Color.gray.opacity(0.2),
                        lineWidth: isActiveFocus ? 1.5 : 0.5
                    )
            )
            .onTapGesture {
                if !isActiveFocus {
                    isTextFieldFocused = true
                    feedbackGenerator.impactOccurred(intensity: 0.4)
                }
            }
        }
        .padding(.horizontal, 2)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTextFieldFocused)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: text)
        .onChange(of: isActive) { newValue in
            if newValue {
                isTextFieldFocused = true
            }
        }
    }
}

#Preview {
    IconPickerView(
        selectedIcon: .constant("star.fill"),
        iconColor: .blue,
        isPresented: .constant(true)
    )
}
