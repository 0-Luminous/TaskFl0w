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

            ZStack {
                // Основное содержимое с иконками
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 70))
                        ], spacing: 20
                    ) {
                        ForEach(filteredIcons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                                feedbackGenerator.impactOccurred()
                                isPresented = false
                            }) {
                                VStack {
                                    ZStack {
                                        Circle()
                                            .fill(iconColor)
                                            .frame(width: 50, height: 50)

                                        Image(systemName: icon)
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                    }

                                    Text(icon)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .frame(width: 70)
                                }
                            }
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        icon == selectedIcon
                                            ? (colorScheme == .dark
                                                ? Color(UIColor.systemGray5)
                                                : Color(UIColor.systemGray6)) : Color.clear)
                            )
                        }
                    }
                    .padding()
                    .padding(.bottom, 90) // Увеличиваем отступ для более высокого докбара
                }
                
                VStack {
                    Spacer()
                    // Докбар для категорий
                    IconPickerDockBar(selectedCategory: $selectedCategory)
                        .frame(height: 100) // Уменьшаем высоту докбара
                        .background(
                            Rectangle()
                                .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: -4)
                        )
                }
            }
            .navigationTitle("Выбор иконки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        feedbackGenerator.impactOccurred()
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        feedbackGenerator.impactOccurred()
                        isPresented = false
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// Компонент докбара для категорий
struct IconPickerDockBar: View {
    @Binding var selectedCategory: IconPickerView.IconCategory
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) { // Увеличиваем расстояние между элементами
                ForEach(IconPickerView.IconCategory.allCases) { category in
                    Button(action: {
                        withAnimation {
                            selectedCategory = category
                        }
                    }) {
                        VStack(spacing: 6) { // Увеличиваем расстояние между иконкой и текстом
                            ZStack {
                                // Добавляем фоновую подсветку для выбранной категории
                                if selectedCategory == category {
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.2))
                                        .frame(width: 52, height: 52)
                                }
                                
                                Image(systemName: category.systemName)
                                    .font(.system(size: 26)) // Увеличиваем размер иконок
                                    .foregroundColor(
                                        selectedCategory == category
                                        ? .accentColor
                                        : (colorScheme == .dark ? .white : .gray)
                                    )
                                    .frame(width: 50, height: 50)
                            }
                            
                            // Показываем текст только для выбранной категории
                            if selectedCategory == category {
                                Text(category.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.accentColor)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .transition(.opacity)
                            } else {
                                // Используем прозрачный элемент той же высоты для сохранения выравнивания
                                Text(" ")
                                    .font(.system(size: 12))
                                    .foregroundColor(.clear)
                                    .opacity(0)
                                    .frame(height: 15) // Высота текстового блока
                            }
                        }
                        .frame(width: 65) // Увеличиваем ширину для более просторного размещения
                        .padding(.top, 8)
                        .padding(.bottom, 20) // Добавляем вертикальные отступы для кнопок
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6) // Добавляем вертикальные отступы
        }
    }
}

struct IconSearchBar: View {
    @Binding var text: String
    @Binding var isActive: Bool

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Поиск", text: $text)
                .disableAutocorrection(true)

            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemGray6))
        )
    }
}

#Preview {
    IconPickerView(
        selectedIcon: .constant("star.fill"),
        iconColor: .blue,
        isPresented: .constant(true)
    )
}
